module Houcho
  module Spec::Runner

    require 'awesome_print'
    module_function
    def prepare(roles, ex_hosts, hosts, specs)
      runlist = {}
      Role.details(roles).each do |role, detail|
        r         = {}
        r['spec'] = (detail['spec']||[]).map {|spec| 'spec/' + spec + '_spec.rb'}
        r['host'] = detail['host']||[]

        (detail['cf']||{}).each do |cfrole, value|
          r['host'] += value['host']
        end
        r['host'] -= ex_hosts

        runlist[role] = r
      end

      m         = {}
      m['host'] = hosts if ! hosts.empty?
      m['spec'] = specs.map {|spec| 'spec/' + spec + '_spec.rb'} if ! specs.empty?

      runlist[:'run manually'] = m if m != {}

      runlist
    end


    def exec(roles, ex_hosts, hosts, specs, ci = {}, dryrun = nil)
      self.prepare(roles, ex_hosts, hosts, specs).each do |role, v|
        command = "parallel_rspec #{v['spec'].sort.uniq.join(' ')}"

        if dryrun
          v['host'].each do |host| 
            puts "TARGET_HOST=#{host} #{command}"
          end
          next
        end

        v['host'].each do |host|
          ENV['TARGET_HOST'] = host
          result = systemu command
          result_status = result[0] == 0 ? 1 : 2
          puts result[1].scan(/\d* examples?, \d* failures?\n/).first.chomp + "\t#{host}, #{executable_specs}\n"

          post_result(result, role, host, command, ci)
          $fail_runspec = true if result_status != 1
        end
      end
    end


    def post_result(result, role, host, command, ci)
      if ci[:ukigumo]
        @conf = YAML.load_file('conf/houcho.conf')
        ukigumo_report = CI::UkigumoClient.new(@conf['ukigumo']['host'], @conf['ukigumo']['port']).post({
          :status   => result_status,
          :project  => role,
          :branch   => host.gsub(/\./, '-'),
          :repo     => @conf['git']['uri'],
          :revision => `git log spec/| grep '^commit' | head -1 | awk '{print $2}'`.chomp,
          :vc_log   => command,
          :body     => result[1],
        })
      end

      if ci[:ikachan] && result_status != 1
        message  = "[serverspec fail]\`TARGET_HOST=#{host} #{command}\` "
        message += JSON.parse(ukigumo_report)['report']['url'] if ukigumo_report
        @conf = YAML.load_file('conf/houcho.conf')
        CI::IkachanClient.new(
          @conf['ikachan']['channel'],
          @conf['ikachan']['host'],
          @conf['ikachan']['port']
        ).post(message)
      end
    end


    def check(specs, host_count)
      puts 'work in progress'; exit

      specs = specs.flatten
      rh    = cfload

      specs.each do |spec|
        hosts   = []
        indexes = Spec.indexes(spec)

        if indexes.empty?
          puts "#{spec} has not attached to any roles"
          next
        end

        indexes.each do |index|
          hosts += Host.elements(index)
          CloudForecast::Role.elements(index).each do |cfrole|
            hosts += rh[cfrole]
          end
        end
        hosts.sample(host_count).each {|host| runspec(nil, host, [spec])}
      end
    end
  end
end
