require 'rubygems'
require 'thor'
require 'houcho'
require 'houcho/role'
require 'houcho/host'
require 'houcho/spec'
require 'houcho/spec/runner'
require 'houcho/cloudforecast'
require 'houcho/cloudforecast/role'
require 'houcho/cloudforecast/host'

include Houcho

module Helper
  module_function

  def empty_args(klass, chell, mesod)
    klass.class.task_help(chell, mesod)
    exit
  end
end


class Thor::MyHelper < Thor
  class_option :help, :type => :boolean, :aliases => '-h', :desc => 'Help message.'

  no_tasks do
    def invoke_task(task, *args)
      if options[:help] && task.name != 'help'
        self.class.task_help(shell, task.name)
      else
        super
      end
    end
  end

  def self.banner(task, namespace = false, subcommand = true)
    super
  end
end


class SpecConduct < Thor::MyHelper
  namespace :spec

  desc 'details [spec1 spec2 spec3...]', 'show details about spec'
  def details(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    puts_details(Spec.details(args))
  end

  desc 'show', 'show all of specs'
  def show
    puts Spec.elements.sort.join("\n")
  end

  desc 'attach [spec1 spec2 spec3...] --roles [role1 role2...]', 'attach spec to role'
  option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
  def attach(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    Spec.attach(args, options[:roles]) rescue puts $!.message; exit!
  end

  desc 'detach [spec1 spec2 spec3...] --roles [role1 role2...]', 'detach spec from spec'
  option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
  def detach(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    Spec.detach(args, options[:roles]) rescue puts $!.message; exit!
  end

  desc 'check [options]', 'run the spec sampled appropriately to the associated host'
  option :sample_host_count, :type => :numeric, :default => 5, :desc => 'number of sample hosts'
  def check(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?

    begin
      messages = Spec::Runner.check(args, options[:sample_host_count])
    rescue
      puts $!.message
      exit!
    end

    messages.each do |msg|
      puts msg
    end
  end

  desc 'exec (spec1 spec2..) [options]', 'run serverspec manually'
  option :hosts,   :type => :array,   :desc => '--hosts host1 host2 host3...', :required => true
  option :ukigumo, :type => :boolean, :desc => 'post results to UkigumoServer'
  option :ikachan, :type => :boolean, :desc => 'post fail results to Ikachan'
  option :dry_run, :type => :boolean, :desc => 'show commands that may exexute'
  def exec(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?

    begin
      messages = Spec::Runner.exec(
        [], [], options[:hosts], args,
        {
          ukigumo: options[:ukigumo],
          ikachan: options[:ikachan],
        },
        options[:dry_run],
      )
    rescue
      puts $!.message
      exit!
    end

    messages.each do |msg|
      puts msg
    end
  end
end


class HostConduct < Thor::MyHelper
  namespace :host

  desc 'details [host1 host2 host3...]', 'show details about host'
  def details(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    puts_details(Host.details(args))
  end

  desc 'show', 'show all of hosts'
  def show
    puts (Host.elements + CloudForecast::Host.all).join("\n")
  end

  desc 'attach [host1 host2 host3...] --roles [role1 role2...]', 'attach host to role'
  option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
  def attach(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    Host.attach(args, options[:roles]) rescue puts $!.message; exit!
  end

  desc 'detach [host1 host2 host3...] --roles [role1 role2...]', 'detach host from role'
  option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
  def detach(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    Host.detach(args, options[:roles]) rescue puts $!.message; exit!
  end
end


class RoleConduct < Thor::MyHelper
  namespace :role

  desc 'create [role1 role2 role3...]', 'cretate role'
  def create(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    Role.create(args) rescue puts $!.message; exit!
  end

  desc 'delete [role1 role2 role3...]', 'delete a role'
  def delete(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    Role.delete(args) rescue puts $!.message; exit!
  end

  desc 'rename [exist role] [name]', 'rename a role'
  def rename(role, rename)
    Role.rename(role, rename) rescue puts $!.message; exit!
  end

  desc 'details [role1 role2...]', 'show details about role'
  def details(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    puts_details(Role.details(args))
  end

  desc 'show', 'show all of roles'
  def show
    puts Role.all.join("\n")
  end

  desc 'exec (role1 role2..) [options]', 'run role'
  option :exclude_hosts, :type => :array, :desc => '--exclude-hosts host1 host2 host3...'
  option :ukigumo, :type => :boolean, :desc => 'post results to UkigumoServer'
  option :ikachan, :type => :boolean, :desc => 'post fail results to Ikachan'
  option :dry_run, :type => :boolean, :desc => 'show commands that may exexute'
  def exec(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?

    begin
      messages = Spec::Runner.exec(
        args, (options[:exclude_hosts]||[]), [], [],
        {
          ukigumo: options[:ukigumo],
          ikachan: options[:ikachan],
        },
        options[:dry_run],
      )
    rescue
      puts $!.message
      exit!
    end

    messages.each do |msg|
      puts msg
    end
  end
end


class CFConduct < Thor::MyHelper
  namespace :cf

  desc "details [cf1 cf2 cf3...]", "show details about cloudforecast's role"
  def details(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    puts_details(CloudForecast::Role.details(args))
  end

  desc 'show', "show all of cloudforecast's roles"
  def show
    puts CloudForecast::Role.all.sort.join("\n")
  end

  desc 'attach [cf1 cf2 cf3...] --roles [role1 role2...]', "attach cloudforecast's role to role"
  option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
  def attach(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    CloudForecast::Role.attach(args, options[:roles]) rescue puts $!.message; exit!
  end

  desc 'detach [cf1 cf2 cf3...] --roles [role1 role2...]', "detach cloudforecast's role from role"
  option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
  def detach(*args)
    Helper.empty_args(self, shell, __method__) if args.empty?
    CloudForecast::Role.detach(args, options[:roles]) rescue puts $!.message; exit!
  end

  desc 'load', '(re)loading yamls of cloudforecast'
  def load
    CloudForecast.load
  end
end


module Houcho
  class CLI < Thor
    register(CFConduct,   'cf',   'cf [attach|detach|show|details|load]', 'operate relevant to CloudForecast')
    register(RoleConduct, 'role', 'role [create|delete|rename|show|details|exec]', 'operate roles')
    register(HostConduct, 'host', 'host [attach|detach|show|details]', 'operate hosts')
    register(SpecConduct, 'spec', 'spec [attach|detach|show|details|exec|check]', 'operate specs')

    class_option :help, :type => :boolean, :aliases => '-h', :desc => 'Help message.'
    no_tasks do
      def invoke_task(task, *args)
        if options[:help] && ! %w{role host spec cf help}.include?(task.name)
          CLI.task_help(shell, task.name)
        else
          super
        end
      end
    end

    desc 'init', 'set houcho repository on current directory'
    def init
      init_repo
    end
  end
end
