# -*- encoding: utf-8 -*-
def app_dir
  File.expand_path("#{File.dirname(__FILE__)}/..")
end

require 'awesome_print'
require 'rainbow'
require 'parallel'
require 'systemu'
require 'tempfile'
require 'find'
require 'yaml'
require 'json'
require app_dir + "/lib/CI"
require app_dir + "/lib/RoleHandle"

class Conductor
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
    # ヒアドキュメントのところ、外部ファイルを置いてそれを参照するようにしたほうがよさそうね
    %W{conf role/cloudforecast spec}.each do |d|
      FileUtils.mkdir_p d if ! Dir.exists? d
    end

    File.write('./role/cloudforecast/houcho_sample.yaml', <<EOH
--- houcho
servers:
  - label: author
  - config: studio3104
    hosts:
      - studio3104.test
      - studio3105.test
      - studio3106.test
      - studio3107.test
      - studio3108.test
      - studio3109.test
      - studio3110.test
EOH
    ) if ! File.exists? './role/cloudforecast/houcho_sample.yaml'

    File.write('./spec/spec_helper.rb', <<EOH
require 'serverspec'
require 'pathname'
require 'net/ssh'

include Serverspec::Helper::Ssh
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end
  c.before :all do
    block = self.class.metadata[:example_group_block]
    if RUBY_VERSION.start_with?('1.8')
      file = block.to_s.match(/.*@(.*):[0-9]+>/)[1]
    else
      file = block.source_location.first
    end
    c.ssh.close if c.ssh
    c.host  = ENV['TARGET_HOST']
    options = Net::SSH::Config.for(c.host)
    user    = options[:user] || Etc.getlogin
    c.ssh   = Net::SSH.start(c.host, user, options)
    c.os    = backend(Serverspec::Commands::Base).check_os
  end
end
EOH
    ) if ! File.exists? './spec/spec_helper.rb'

    File.write('./conf/houcho.conf', {
      'ukigumo' => {'host' => nil, 'port' => nil,},
      'ikachan' => {'host' => nil, 'port' => nil, 'channel' => [nil],},
      'git'     => {'uri'  => nil,},
    }.to_yaml) if ! File.exists? './conf/houcho.conf'

    %w{
      runlists.yaml
      roles.yaml
      hosts.yaml
      specs.yaml
      cf_roles.yaml
      hosts_ignored.yaml
      cloudforecast.yaml
    }.each do |f|
      f = 'role/' + f
      File.write(f, '') if ! File.exists? f
    end

    File.open("./.houcho", "w").close()
    `git init; git add .; git commit -a -m 'initial commit'` if ! Dir.exists?('./.git')
  end

  def show_all_cf_roles
    puts cfload.keys.sort.join("\n")
  end

  def show_all_roles
    puts RoleHandle::YamlLoader.new('./role/roles.yaml').data.values.sort.join("\n")
  end

  def show_all_hosts
    puts (cfload.values.flatten.uniq + hosthandle.elements).join("\n")
  end

  def show_all_specs
    puts spechandle.elements.sort.join("\n")
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


  def show_role_details(role)
    puts_details(role_details(role))
  end


  def show_host_details(host)
    h       = hosthandle
    r       = rolehandle
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
      ih = ignorehosthandle
      result[host]["[cloudforecast's role]"] = {}
      cfroles.each do |cfrole|
        result[host]["[cloudforecast's role]"][cfrole] = []
        cf.indexes(cfrole).each do |index|
          res = ih.data.include?(host) ? '<ignored>' + r.name(index) + '</ignored>' : r.name(index)
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


  def create_runlist(runlist)
    rlh = runlisthandle
    abort("runlist(#{runlist}) already exist") if rlh.data.has_key?(runlist)
    rlh.data[runlist] = []
    rlh.save_to_file
  end


  def delete_runlist(runlist)
    rlh = runlisthandle
    abort("runlist(#{runlist}) does not exist") if ! rlh.data.has_key?(runlist)
    abort("exclude role(s) from runlist before delete runlist") if ! rlh.data[runlist].empty?
    rlh.data.delete(runlist)
    rlh.save_to_file
  end


  def include_role_among_runlist(role, runlist)
    rlh = runlisthandle
    abort("runlist(#{runlist}) does not exist") if ! rlh.data.has_key?(runlist)
    index = validate_role(role)
    rlh.data[runlist] << index
    rlh.save_to_file
  end


  def exclude_role_from_runlist(role, runlist)
    rlh = runlisthandle
    abort("runlist(#{runlist}) does not exist") if ! rlh.data.has_key?(runlist)
    index = validate_role(role)
    rlh.data[runlist].delete(index)
    rlh.save_to_file
  end


  def rename_runlist(runlist, rename)
    rlh = runlisthandle
    abort("runlist(#{runlist}) does not exist") if ! rlh.data.has_key?(runlist)
    abort("runlist(#{rename}) already exist") if rlh.data.has_key?(rename)
    rlh.data[rename] = rlh.data[runlist]
    rlh.data.delete(runlist)
    rlh.save_to_file
  end


  def show_runlist_details(runlist)
    rlh = runlisthandle
    r   = rolehandle
    abort("runlist(#{runlist}) does not exist") if ! rlh.data.has_key?(runlist)

    roledetails = {}
    rlh.data[runlist].each do |roleindex|
      roledetails.merge!(role_details(r.name(roleindex)))
    end

    puts_details({
      runlist => {
        '[role]' => roledetails
      }
    })
  end


  def show_all_runlists
    puts runlisthandle.data.keys.sort.join("\n")
  end


  def create_role(role)
    r     = rolehandle
    index = r.index(role)
    abort("role(#{role}) already exist") if index
    r.create(role)
  end


  def delete_role(role)
    r     = rolehandle
    index = r.index(role)
    abort("role(#{role}) does not exist") if ! index
    abort("detach host(s) from #{role} before delete #{role}") if hosthandle.has_data?(index)
    abort("detach spec(s) from #{role} before delete #{role}") if spechandle.has_data?(index)
    abort("detach cloudforecast's role(s) from #{role} before delete #{role}") if cfrolehandle.has_data?(index)
    r.delete(index)
  end


  def rename_role(role, name)
    r     = rolehandle
    index = r.index(role)
    abort("#{role} does not exist") if ! index
    abort("#{name} already exist") if r.index(name)
    r.rename(index, name)
  end


  def attach_host_to_role(host, role)
    index = validate_role(role)
    h     = hosthandle
    abort("#{host} has already attached to #{role}") if h.attached?(index, host)
    h.attach(index, host)
  end


  def detach_host_from_role(host, role)
    index = validate_role(role)
    h     = hosthandle
    abort("#{host} does not attach to #{role}") if ! h.attached?(index, host)
    h.detach(index, host)
  end


  def ignore_host(host)
    ih = ignorehosthandle
    ih.data = Hash === ih.data ? [] : ih.data
    abort("#{host} has already included into ignore list") if ih.data.include?(host)
    ih.data << host
    ih.save_to_file
  end


  def disignore_host(host)
    ih = ignorehosthandle
    ih.data = Hash === ih.data ? [] : ih.data
    abort("#{host} does not include into ignore list") if ! ih.data.include?(host)
    ih.data.delete(host)
    ih.save_to_file
  end


  def attach_spec_to_role(spec, role)
    index = validate_role(role)
    s     = spechandle
    abort("#{spec} already attach to #{role}") if s.attached?(index, spec)
    s.attach(index, spec)
  end


  def detach_spec_from_role(spec, role)
    index = validate_role(role)
    s     = spechandle
    abort("#{spec} does not attach to #{role}") if ! s.attached?(index, spec)
    s.detach(index, spec)
  end


  def attach_cfrole_to_role(cf_role, role)
    index = validate_role(role)
    cr    = cfrolehandle
    abort("#{cf_role} does not exist in cloudforecast's yaml") if ! cfload.has_key?(cf_role)
    abort("#{cf_role} already attach to #{role}") if cr.attached?(index, cf_role)
    cr.attach(index, cf_role)
  end


  def detach_cfrole_from_role(cf_role, role)
    index = validate_role(role)
    cr    = cfrolehandle
    abort("#{cf_role} does not attach to #{role}") if ! cr.attached?(index, cf_role)
    cr.detach(index, cf_role)
  end


  def runspec_all(ci, dry)
    roles = RoleHandle::YamlLoader.new('./role/roles.yaml').data.values.sort
  end


  def runspec_by_role(role, ci, dry)
    index  = validate_role(role)
    rh     = cfload
    hosts  = hosthandle.elements(index)
    specs  = spechandle.elements(index)

    cfrolehandle.elements(index).each do |cf_role|
      if rh[cf_role].nil?
        p cf_role
        next
      end
      hosts += rh[cf_role]
    end

    hosts = hosts.uniq - ignorehosthandle.data.to_a

    processor_count = dry ? 1 : Parallel.processor_count
    Parallel.each(hosts, in_threads: processor_count) do |host|
      runspec(role, host, specs, ci, dry)
    end
  end

  private
  def validate_role(role)
    index = rolehandle.index(role)
    abort("role(#{role}) does not exist") if ! index
    index
  end

  def cfload
    RoleHandle::YamlLoader.new('./role/cloudforecast.yaml').data
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

  def ignorehosthandle
    RoleHandle::YamlEditor.new('./role/hosts_ignored.yaml')
  end

  def spechandle
    RoleHandle::ElementHandler.new('./role/specs.yaml')
  end

  def runspec(role, host, specs, ci, dryrun = nil)
    executable_specs = specs.map {|spec| 'spec/' + spec + '_spec.rb'}.join(' ')
    command          = "rspec #{executable_specs}"
    if dryrun
      puts 'TARGET_HOST=' + host + ' ' + command
      return
    end

    ENV['TARGET_HOST'] = host
    result = systemu command + ' --format documentation'
    result_status = result[0] == 0 ? 1 : 2
    puts result[1].scan(/\d* examples?, \d* failures?\n/).first.chomp + "\t#{host}, #{executable_specs}\n"

    if ci[:ukigumo]
      @conf = YAML.load_file('conf/houcho.conf')
      ukigumo_report = CI::UkigumoClient.new(@conf['ukigumo']['host'], @conf['ukigumo']['port']).post({
        :status   => result_status,
        :project  => role.gsub(/\./, '-'),
        :branch   => host.gsub(/\./, '-'),
        :repo     => @conf['git']['uri'],
        :revision => `git log spec/| grep '^commit' | head -1 | awk '{print $2}'`.chomp,
        :vc_log   => '',
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


  def puts_details(e, indentsize = 0, cnt = 1)
    case e
    when Array
      e.sort.each.with_index(1) do |v, i|
        (indentsize-1).times {print '   '}
        print i != e.size ? '├─ ' : '└─ '
        puts v =~ /^<ignored>.*<\/ignored>$/ ? v.color(:red) : v.color(240,230,140)
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


  def role_details(role)
    index = validate_role(role)

    ih = ignorehosthandle

    hosts   = hosthandle.elements(index)
    specs   = spechandle.elements(index)
    cfroles = cfrolehandle.elements(index)

    result = {role => {}}

    if ! hosts.empty?
      hosts.each do |h|
        host = ih.data.include?(h) ? '<ignored>' + h + '</ignored>' : h
        result[role]['[host]'] ||= []
        result[role]['[host]'] << host
      end
    end
    result[role]['[spec]'] = specs if ! specs.empty?

    if ! cfroles.empty?
      rh = cfload
      result[role]["[cloudforecast's]"] = {}
      cfroles.each do |cr|
        result[role]["[cloudforecast's]"][cr] = {}
        if ! (rh[cr]||[]).empty?
          result[role]["[cloudforecast's]"][cr]['[host]'] = []
          rh[cr].each do |h|
            host = ih.data.include?(h) ? '<ignored>' + h + '</ignored>' : h
            result[role]["[cloudforecast's]"][cr]['[host]'] << host
          end
        end
      end
    end

    result
  end
end
