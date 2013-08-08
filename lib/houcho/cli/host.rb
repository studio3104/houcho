require 'thor'
require 'houcho/host'
require 'houcho/cli/host/attribute'

module Houcho
  module CLI
    class Host < Thor
      register(Houcho::CLI::HostAttribute, 'attr', 'attr [set|get|delete]', 'operation of host attribute')
      namespace :host
      @@h = Houcho::Host.new


      desc 'list', 'show all of host list'
      def list
        puts @@h.list.sort.join("\n")
      end


      desc 'attach [host1 host2 host3...] --roles [role1 role2...]', 'attach host to role'
      option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
      def attach(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        @@h.attach(args, options[:roles])
      rescue RoleExistenceException, SpecFileException, SQLite3::ConstraintException => e
        puts e.message
        exit!
      end


      desc 'detach [spec1 spec2 spec3...] --roles [role1 role2...]', 'detach spec from spec'
      option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
      def detach(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        @@h.detach(args, options[:roles])
      rescue RoleExistenceException, SQLite3::ConstraintException => e
        puts e.message
        exit!
      end


      desc 'details [spec1 spec2 spec3...]', 'show details about spec'
      def details(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        Houcho::CLI::Main.puts_details(@@h.details(args))
      end
    end
  end
end
