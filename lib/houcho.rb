# -*- encoding: utf-8 -*-
require 'awesome_print'
require 'rainbow'
require 'parallel'
require 'systemu'
require 'tempfile'
require 'find'
require 'yaml'
require 'json'
require 'houcho/initialize'
#require 'houcho/ci'
require 'houcho/role'
require 'houcho/host'
require 'houcho/spec'
require 'houcho/spec/runner'

module Houcho
  def configure_houcho
    cf_yamls = Tempfile.new('yaml')
    File.open(cf_yamls,'a') do |t|
      Find.find('./role/cloudforecast') do |f|
        t.write File.read(f) if f =~ /\.yaml$/
      end
    end

    cf = YamlHandle::CfLoader.new(cf_yamls)
    File.write('./role/cloudforecast.yaml', cf.role_hosts.to_yaml)
  end


  def show_all_cf_roles
    puts cfload.keys.sort.join("\n")
  end

  def show_all_hosts
    puts (CloudForecast::Role.values.flatten.uniq + Host.elements).join("\n")
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
        puts v
      end
      puts ''
    when Hash
      e.each do |k,v|
        if ! indentsize.zero?
          (indentsize).times {print '   '}
        end
        k = k.color(0,255,0)
        k = '[' + k.color(219,112,147) + ']' if indentsize.zero?
        puts k
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
end
