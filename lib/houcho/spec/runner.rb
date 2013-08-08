require "yaml"
require "systemu"
require "json"
require "logger"
require "houcho/role"
require "houcho/spec"
require "houcho/ci"
require "houcho/config"

module Houcho

class Spec
  class Runner
    def initialize
      @role = Houcho::Role.new
      @host = Houcho::Host.new
      @spec = Houcho::Spec.new
      @specdir = Houcho::Config::SPECDIR
      @logger = Logger.new(Houcho::Config::SPECLOG, 10)
    end


    def check(spec, host_count, dry_run = false) #dry_run for test
      spec = spec.is_a?(Array) ? spec : [spec]
      role = spec.map { |s| @spec.details(s)[s]["role"] }.flatten
      host = []

      @role.details(role).each do |rolename, value|
        host.concat(value["host"]).uniq if value["host"]

        if value["outer role"]
          value["outer role"].each do |outerrolename, v|
            host.concat(v["host"]).uniq if v["host"]
          end
        end
      end

      execute_manually(host.sample(host_count), spec, dry_run)
    end


    def execute_manually(host, spec, dryrun = false, console_output = false)
      host = host.is_a?(Array) ? host : [host]
      spec = spec.is_a?(Array) ? spec : [spec]

      run(
        { "manually" => { "host" => host, "spec" => spec } },
        dryrun,
        console_output
      )
    end


    def execute_role(role, ex_host = [], dryrun = false, console_output = false)
      role = role.is_a?(Array) ? role : [role]
      ex_host = ex_host.is_a?(Array) ? ex_host : [ex_host]

      role_valiables = {}

      @role.details(role).each do |rolename, value|
        next unless value["spec"]

        rv ||= {}
        rv["host"] ||= []
        rv["spec"] ||= []

        rv["spec"].concat(value["spec"]).uniq
        rv["host"].concat(value["host"]).uniq if value["host"]

        if value["outer role"]
          value["outer role"].each do |outerrolename, v|
            rv["host"].concat(v["host"]).uniq if v["host"]
          end
        end

        rv["host"] = rv["host"] - ex_host
        role_valiables[rolename] = rv
      end

      run(role_valiables, dryrun, true, console_output)
    end


    def run(target, dryrun, ci = false, console_output = false)
      messages = []

      target.each do |role, v|
        @spec.check_existenxe(v["spec"])
        spec = v["spec"].map { |spec| "#{@specdir}/#{spec}_spec.rb" }
        command = "parallel_rspec #{spec.sort.uniq.join(" ")}"

        if dryrun
          v["host"].each do |host|
            drymsg = "TARGET_HOST=#{host} #{command}"
            puts drymsg if console_output
            messages << drymsg
          end
          next
        end

        v["host"].each do |host|
          result = systemu(
            command,
            :env => {
              "TARGET_HOST" => host,
              "TARGET_HOST_ATTR" => @host.get_attr_json(host)
            },
            :cwd => File.join(@specdir, "..")
          )
          @logger.info(host) {result[1]}
          msg = result[1].scan(/\d* examples?, \d* failures?\n/).first.chomp
          msg += "\t#{host} => #{v["spec"].join(", ")}\n"
          puts msg if console_output
          messages << msg

          post_result(result, role, host, v["spec"], command) if ci
        end
      end

      messages
    end


    def post_result(result, role, host, spec, command)
      result_status = result[0] == 0 ? 1 : 2

      ukigumo = Houcho::Config::UKIGUMO
      ikachan = Houcho::Config::IKACHAN
      git = Houcho::Config::GIT

      if ukigumo["host"] != "" && ukigumo["port"] != "" && git["uri"]
        u = CI::UkigumoClient.new(ukigumo["host"], ukigumo["port"])
        ukigumo_report = u.post({
          :status   => result_status,
          :project  => host.gsub(/\./, "-"),
          :branch   => role,
          :repo     => git["uri"],
          :revision => spec.join(", "),
          :vc_log   => command,
          :body     => result[1],
        })
      end

      if ikachan["host"] != "" && ikachan["port"] != "" && result_status != 1
        message = "[serverspec fail] #{host} => #{spec.join(", ")}"
        message += " (#{JSON.parse(ukigumo_report)["report"]["url"]})" if ukigumo_report

        i = CI::IkachanClient.new(
          ikachan["channel"],
          ikachan["host"],
          ikachan["port"]
        )

        i.post(message)
      end
    end
  end
end

end
