module Houcho
  module Spec::Runner
    module_function

    def prepare(roles, ex_hosts, hosts, specs)
      runlist        = {}
      spec_not_exist = []

      spec_check = Proc.new do |specs|
        p = specs.map {|spec|'spec/' + spec + '_spec.rb'}.partition {|spes|File.exist?(spes)}
        spec_not_exist += p[1].map {|e|e.sub(/^spec\//,'').sub(/_spec.rb$/,'')}
        p[0]
      end

      Role.details(roles).each do |role, detail|
        r         = {}
        r['spec'] = spec_check.call(detail['spec']||[])
        r['host'] = detail['host']||[]

        (detail['cf']||{}).each do |cfrole, value|
          r['host'] += value['host']
        end
        r['host'] -= ex_hosts

        runlist[role] = r
      end

      m         = {}
      m['host'] = hosts if ! hosts.empty?
      m['spec'] = spec_check.call(specs) if ! specs.empty?

      runlist[:'run manually'] = m if m != {}

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

          post_result(result, role, host, command, ci) if ci != {}
          $houcho_fail = true if result[0] != 0
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
        CI::IkachanClient.new(
          conf['ikachan']['channel'],
          conf['ikachan']['host'],
          conf['ikachan']['port']
        ).post(message)
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
        hosts.sample(host_count).each {|host| messages += exec([], [], [host], [spec], {}, dryrun)}
      end

      if error.empty?
        messages
      else
        raise("role(#{error.join(',')}) has not attached to any roles")
      end
    end
  end
end
