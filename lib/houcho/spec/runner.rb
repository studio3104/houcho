require "yaml"
require "systemu"
require "json"
require "logger"
require "parallel"
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
      @outerrole = Houcho::OuterRole.new
      @specdir = Houcho::Config::SPECDIR
      @logger = Logger.new(Houcho::Config::SPECLOG, 10)
    end


    def check(spec, host_count, dry_run = false, console_output = false) #dry_run for test
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

      execute_manually(host.sample(host_count), spec, dry_run, console_output)
    end


    def execute_manually(host, spec, dryrun = false, console_output = false)
      host = host.is_a?(Array) ? host : [host]
      spec = spec.is_a?(Array) ? spec : [spec]

      run(
        { rand(36**50).to_s(36) => { "host" => host, "spec" => spec } },
        dryrun,
        false,
        console_output
      )
    end


    def execute_role(role, ex_host = [], dryrun = false, console_output = false)
      role = role.is_a?(Array) ? role : [role]
      ex_host = ex_host.is_a?(Array) ? ex_host : [ex_host]

      role_valiables = {}

      @role.details(role).each do |rolename, value|
        next unless value["spec"]

        rv = {}
        rv["host"] = []
        rv["spec"] = []

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


    private
    def run(target, dryrun, ci = false, console_output = false)
      messages = []
      failure = false

      target.each do |role, v|
        @spec.check_existence(v["spec"])
        spec = v["spec"].map { |spec| "#{@specdir}/#{spec}_spec.rb" }
        command = "rspec --format documentation #{spec.sort.uniq.join(" ")}"
        defined_spec_attr = grep_spec_attr(spec)

        if dryrun
          v["host"].each do |host|
            drymsg = "TARGET_HOST=#{host} #{command}"
            puts drymsg if console_output
            messages << drymsg
          end
          next
        end

        Parallel.each(v["host"], :in_threads => Parallel.processor_count)  do |host|
          if !defined_spec_attr.empty?
            attr = generate_attr(role, host)
            attr.delete_if { |name, value| !defined_spec_attr.include?(name.to_s) }
          end

          result = systemu(
            command,
            :env => {
              "TARGET_HOST" => host,
              "TARGET_HOST_ATTR" => attr ? JSON.generate(attr) : "{}"
            },
            :cwd => File.join(@specdir, "..")
          )

          logmsg = attr.empty? ? "" : "attribute that has been set: #{attr}"
          if !result[1].empty?
            @logger.info(host) { logmsg } unless result[1].empty?
            @logger.info(host) { result[1] }
          end
          @logger.warn(host) { result[2] } unless result[2].empty?

          failure = true if result[0] != 0

          if console_output
            msg = result[1].scan(/\d* examples?, \d* failures?\n/).first
            msg = msg ? msg.chomp : "error"
            msg += "\t#{host} => #{v["spec"].join(", ")}\n"
            puts msg
          end

          if ci
            begin
              post_result(result, role, host, v["spec"], command, logmsg)
            rescue => e
              ci = false
            end
          end
        end
      end

      failure ? false : messages
    end


    def grep_spec_attr(spec)
      attr = []

      spec.each do |s|
        File.open(s).each_line do |l|
          /attr\[\:(?<name>.+)\]/ =~ l
          attr << name
        end
      end

      attr.compact.uniq
    end


    def generate_attr(role, host)
      attr_role = @role.get_attr(role)
      attr_host = @host.get_attr(host)
      attr_outerrole = {}
      outerrole = []

      @host.details(host).each do |h, v|
        outerrole = outerrole.concat((v["outer role"] || [])).uniq
      end

      outerrole.each do |o|
        attr_outerrole.merge!(@outerrole.get_attr(o))
      end

      attr = attr_role.merge(attr_outerrole)
      attr = attr.merge(attr_host)

      if attr != {} && attr_host == {} && outerrole.size > 1
        log = "might not be given the appropriate attribute value, because #{host} have no attributes and belongs to more than one outer role - #{outerrole.join(", ")}"
        @logger.warn(host) { log }
      end

      return attr
    end


    def post_result(result, role, host, spec, command, message)
      result_status = result[0] == 0 ? 1 : 2
      result_status = result[2].empty? ? result_status : 3

      # willing to mv to constractor
      conf = YAML.load_file(Houcho::Config::FILE)
      ukigumo = conf["ukigumo"]
      ikachan = conf["ikachan"]

      if ukigumo && ukigumo["host"] != "" && ukigumo["port"] != ""
        u = CI::UkigumoClient.new(ukigumo["host"], ukigumo["port"])
        ukigumo_report = u.post({
          :status   => result_status,
          :project  => "This is test " + host.gsub(/\./, "-"),
          :branch   => role,
          :repo     => "_",
          :revision => spec.join(", "),
          :vc_log   => command,
          :body     => [message, result[1], result[2]].join("\n\n")
        })
      end

      if ikachan && ikachan["host"] != "" && ikachan["port"] != "" && result_status != 1
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
