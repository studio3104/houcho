require 'yaml'
require 'json'
require 'houcho/role'
require 'houcho/host'
require 'houcho/spec'
require 'houcho/cloudforecast/role'
require 'houcho/cloudforecast/host'
require 'houcho/ci'

module Houcho
  module Spec::Runner
    module_function

    def prepare(roles, ex_hosts, hosts, specs)
      runlist = {}
      spec_not_exist = []

      Role.details(roles).each do |role, detail|
        r = {}
        partspec  = Spec.partition(detail['spec']||[])
        r['spec'] = partspec[0]
        r['host'] = detail['host']||[]

        spec_not_exist += partspec[1]

        (detail['cf'] || {}).each do |cfrole, value|
          r['host'] += value['host']
        end
        r['host'].delete(ex_hosts)

        runlist[role] = r
      end

      m         = {}
      partspec  = Spec.partition(specs)
      m['spec'] = partspec[0] if ! partspec[0].empty?
      m['host'] = hosts if ! hosts.empty?

      spec_not_exist += partspec[1]

      runlist[:'run manually'] = m unless m.empty?

      if ! spec_not_exist.empty?
        raise "spec(#{spec_not_exist.join(',')}) file not exist in ./spec directory."
      end
      runlist
    end


    def exec(roles, ex_hosts, hosts, specs, ci = {}, dryrun = nil)
      messages = []
      self.prepare(roles, ex_hosts, hosts, specs).each do |role, v|
        next if v['spec'].empty?
        command = "parallel_rspec #{v['spec'].sort.uniq.join(' ')}"

        if dryrun
          v['host'].each do |host| 
            messages << "TARGET_HOST=#{host} #{command}"
          end
          next
        end

        v['host'].each do |host|
          ENV['TARGET_HOST'] = host
          result = systemu command
          messages << result[1].scan(/\d* examples?, \d* failures?\n/).first.chomp + "\t#{host}, #{command}\n"

          post_result(result, role, host, command, ci) unless ci.empty?
        end
      end
      messages
    end


    def post_result(result, role, host, command, ci)
      conf = YAML.load_file('conf/houcho.conf')
      result_status = result[0] == 0 ? 1 : 2

      if ci[:ukigumo]
        ukigumo_report = CI::UkigumoClient.new(conf['ukigumo']['host'], conf['ukigumo']['port']).post({
          :status   => result_status,
          :project  => role,
          :branch   => host.gsub(/\./, '-'),
          :repo     => conf['git']['uri'],
          :revision => `git log spec/| grep '^commit' | head -1 | awk '{print $2}'`.chomp,
          :vc_log   => command,
          :body     => result[1],
        })
      end

      if ci[:ikachan] && result_status != 1
        message  = "[serverspec fail]\`TARGET_HOST=#{host} #{command}\` "
        message += JSON.parse(ukigumo_report)['report']['url'] if ukigumo_report
        ikachan = CI::IkachanClient.new(
          conf['ikachan']['channel'],
          conf['ikachan']['host'],
          conf['ikachan']['port']
        )
        ikachan.post(message)
      end
    end


    def check(specs, host_count, dryrun = false) # dryrun is for test
      specs    = specs.flatten
      error    = []
      messages = []

      specs.each do |spec|
        hosts   = []
        indexes = Spec.indexes(spec)

        if indexes.empty?
          error << spec
          next
        end

        indexes.each do |index|
          hosts += Host.elements(index)
          CloudForecast::Role.elements(index).each do |cfrole|
            hosts += CloudForecast::Host.new.hosts(cfrole)
          end
        end
        hosts.sample(host_count).each { |host| messages += exec([], [], [host], [spec], {}, dryrun) }
      end

      if error.empty?
        messages
      else
        raise "role(#{error.join(',')}) has not attached to any roles"
      end
    end
  end
end
