require 'thor'
require 'houcho/outerrole'
require 'houcho/outerrole/cloudforecast'

module Houcho
  module CLI
    class OuterRole < Thor
      namespace :host

      @@or = Houcho::OuterRole.new

      desc 'list', 'show all of host list'
      def list
        puts @@or.list.sort.join("\n")
      end


      desc 'attach [outerrole1 outerrole2 outerrole3...] --roles [role1 role2...]', 'attach outer role to role'
      option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
      def attach(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        @@or.attach(args, options[:roles])
      rescue RoleExistenceException, SpecFileException, SQLite3::ConstraintException => e
        puts e.message
        exit!
      end


      desc 'detach [outerrole1 outerrole2 outerrole3...] --roles [role1 role2...]', 'detach outer role from role'
      option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
      def detach(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        @@or.detach(args, options[:roles])
      rescue RoleExistenceException, SQLite3::ConstraintException => e
        puts e.message
        exit!
      end


      desc 'details [outerrole1 outerrole2 outerrole3...]', 'show details about outerrole'
      def details(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        Houcho::CLI::Main.puts_details(@@or.details(args))
      end


      desc 'load', 'load role data from outer system'
      def load
        Houcho::OuterRole::CloudForecast.load
      end
    end
  end
end
