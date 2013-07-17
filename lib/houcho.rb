# -*- encoding: utf-8 -*-
require 'awesome_print'
require 'rainbow'
require 'parallel'
require 'systemu'
require 'tempfile'
require 'find'
require 'yaml'
require 'json'
#require 'houcho/ci'
require 'houcho/role'
#require 'houcho/host'
require 'houcho/initialize'

module Houcho
  def configure_houcho
    cf_yamls = Tempfile.new('yaml')
    File.open(cf_yamls,'a') do |t|
      Find.find('./role/cloudforecast') do |f|
        t.write File.read(f) if f =~ /\.yaml$/
      end
    end

    cf = RoleHandle::CfLoader.new(cf_yamls)
    File.write('./role/cloudforecast.yaml', cf.role_hosts.to_yaml)
  end

  def initialize_houcho
    Initialize
  end

  def show_all_cf_roles
    puts cfload.keys.sort.join("\n")
  end

  def show_all_hosts
    puts (CloudForecast::Role.values.flatten.uniq + Host.elements).join("\n")
  end


  def show_cf_role_details(cf_role)
    rh = cfload
    abort("#{cf_role} does not exist in cloudforecast's yaml") if ! rh.keys.include?(cf_role)

    puts '[host(s)]'
    puts rh[cf_role].join("\n")

    attached_role_indexes = cfrolehandle.indexes(cf_role)
    if ! attached_role_indexes.empty?
      r = rolehandle
      puts ''
      puts '[attached role(s)]'
      attached_role_indexes.each do |index|
        puts r.name(index)
      end
    end
  end


  def show_host_details(host)
    h       = Host
    r       = Role
    indexes = h.indexes(host)
    cfroles = cfload.select {|role, hosts|hosts.include?(host)}.keys

    abort("#{host} has not attached to any roles") if indexes.empty?  && cfroles.empty?

    result = {host => {}}

    if ! indexes.empty?
      result[host]['[attached role(s)]'] = []
      indexes.each do |index|
        result[host]['[attached role(s)]'] << r.name(index)
      end
    end

    if ! cfroles.empty?
      cf = cfrolehandle
      result[host]["[cloudforecast's role]"] = {}
      cfroles.each do |cfrole|
        result[host]["[cloudforecast's role]"][cfrole] = []
        cf.indexes(cfrole).each do |index|
          result[host]["[cloudforecast's role]"][cfrole] << res
        end
      end
    end

    puts_details(result)
  end


  def show_spec_details(spec)
    s       = spechandle
    r       = rolehandle
    indexes = s.indexes(spec)

    abort("#{spec} has not attached to any roles") if indexes.empty?

    result = {spec => {}}

    if ! indexes.empty?
      result[spec]['[attached role(s)]'] = []
      indexes.each do |index|
        result[spec]['[attached role(s)]'] << r.name(index)
      end
    end

    puts_details(result)
  end


  def check_specs(specs, host_count)
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


  def runspec_prepare(roles, hosts, specs, ci, dry)
    rhs = prepare_list(roles, hosts, specs)

    rhs.each do |role, host_specs|
      host_specs.each do |host, specs|
        runspec(role, host, specs, ci, dry)
      end
    end
  end


  def puts_details(e, indentsize = 0, cnt = 1)
    case e
    when Array
      e.sort.each.with_index(1) do |v, i|
        (indentsize-1).times {print '   '}
        print i != e.size ? '├─ ' : '└─ '
      end
      puts ''
    when Hash
      e.each do |k,v|
        if ! indentsize.zero?
          (indentsize).times {print '   '}
        end
        puts k =~ /^\[.*\]$/ ? k : k.color(0,255,0)
        puts '' if indentsize.zero?
        puts_details(v, indentsize+1, cnt+1)
      end
    end
  end


  private
  def prepare_list(roles, hosts, specs)
    role_host_specs = { 'ManuallyRun' => {} }

    rh = cfload
    r  = rolehandle

    hosts.each do |host|
      role_host_specs['ManuallyRun'][host] ||= []
      role_host_specs['ManuallyRun'][host] = (role_host_specs['ManuallyRun'][host] + specs).uniq
    end

    roles.each do |role|
      validate_role(Regexp.new(role)).each do |index|
        _role  = r.name(index)
        _hosts = hosthandle.elements(index)
        _specs = spechandle.elements(index)

        cfrolehandle.elements(index).each do |cf_role|
          if rh[cf_role].nil?
            p cf_role
            next
          end
          _hosts += rh[cf_role]
        end

        role_host_specs[_role] = {}

        _hosts.each do |host|
          role_host_specs[_role][host] ||= []
          role_host_specs[_role][host] = (role_host_specs[_role][host] + _specs).uniq
        end
      end
    end

    role_host_specs
  end

  def validate_role(role)
    if Regexp === role
      indexes = Role.indexes_regexp(role)
      abort if indexes.empty?
      indexes
    else
      index = Role.index(role)
      abort("role(#{role}) does not exist") if ! index
      index
    end
  end

  def cfload
    YamlHandle::Loader.new('./role/cloudforecast.yaml').data
  end

  def runlisthandle
    RoleHandle::YamlEditor.new('./role/runlists.yaml')
  end

  def rolehandle
    RoleHandle::RoleHandler.new('./role/roles.yaml')
  end

  def cfrolehandle
    RoleHandle::ElementHandler.new('./role/cf_roles.yaml')
  end

  def hosthandle
    RoleHandle::ElementHandler.new('./role/hosts.yaml')
  end

  def spechandle
    RoleHandle::ElementHandler.new('./role/specs.yaml')
  end

  def runspec(role, host, specs, ci = {}, dryrun = nil)
    executable_specs = []
    specs.each do |spec|
      if spec =~ /_spec.rb$/
        executable_specs << spec
      else
        executable_specs << 'spec/' + spec + '_spec.rb'
      end
    end

    command = "parallel_rspec #{executable_specs.sort.uniq.join(' ')}"

    if dryrun
      puts 'TARGET_HOST=' + host + ' ' + command
      return
    end

    ENV['TARGET_HOST'] = host
    result = systemu command
    result_status = result[0] == 0 ? 1 : 2
    puts result[1].scan(/\d* examples?, \d* failures?\n/).first.chomp + "\t#{host}, #{executable_specs}\n"

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

    $fail_runspec = true if result_status != 1
  end
end
