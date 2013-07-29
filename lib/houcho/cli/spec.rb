# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

require 'thor'
require 'houcho/spec'
#require 'houcho/spec/runner'
#require 'houcho/console'

module Houcho
  module CLI
    class Spec < Thor
      namespace :spec
      @@s = Houcho::Spec.new


      desc 'list', 'show all of spec list'
      def list
        puts @@s.list.sort.join("\n")
      end


      desc 'attach [spec1 spec2 spec3...] --roles [role1 role2...]', 'attach spec to role'
      option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
      def attach(*args)
        @@s.attach(args, options[:roles])
      rescue RoleExistenceException, SpecFileException, SQLite3::ConstraintException => e
        puts e.message
        exit!
      end


      desc 'detach [spec1 spec2 spec3...] --roles [role1 role2...]', 'detach spec from spec'
      option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
      def detach(*args)
        @@s.detach(args, options[:roles])
      rescue RoleExistenceException, SQLite3::ConstraintException => e
        puts e.message
        exit!
      end


      desc "delete [spec1 spec2 spec3...]", "delete spec file from houcho repository."
      option :force, :aliases => "-f", :type => :boolean, :desc => "delete spec force together with attachment."
      def delete(*args)
        if options[:force]
          @@s.delete_file!(args)
        else
          @@s.delete_file(args)
        end
      rescue SpecFileException => e
        puts e.message
        exit!
      end


      desc 'details [spec1 spec2 spec3...]', 'show details about spec'
      def details(*args)
        p @@s.details(args)
        #Houcho::Console.puts_details(Houcho::Spec.details(args))
      end
    end
  end
end

__END__

    desc 'check [options]', 'run the spec sampled appropriately to the associated host'
    option :sample_host_count, :type => :numeric, :default => 5, :desc => 'number of sample hosts'
    def check(*args)
      Helper.empty_args(self, shell, __method__) if args.empty?

      begin
        messages = Houcho::Spec::Runner.check(args, options[:sample_host_count])
      rescue RuntimeError => e
        puts e.message
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
        messages = Houcho::Spec::Runner.exec(
          [], [], options[:hosts], args,
          {
            ukigumo: options[:ukigumo],
            ikachan: options[:ikachan],
          },
          options[:dry_run],
        )
      rescue RuntimeError => e
        puts e.message
        exit!
      end

      messages.each do |msg|
        puts msg
      end
    end
  end


