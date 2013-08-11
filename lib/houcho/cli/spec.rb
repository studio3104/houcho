require 'thor'
require 'houcho/spec'
require 'houcho/spec/runner'

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


      desc 'detach [spec1 spec2 spec3...]', 'detach spec from spec'
      option :roles, :type => :array, :required => true, :desc => 'specify the roles separated by spaces.'
      def detach(*args)
        @@s.detach(args, options[:roles])
      rescue RoleExistenceException, SQLite3::ConstraintException => e
        puts e.message
        exit!
      end


      desc "rename [from] [to]", "rename spec file"
      def rename(from, to)
        @@s.rename(from, to)
      rescue SpecFileException => e
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
        Houcho::CLI::Main.puts_details(@@s.details(args))
      end


      desc 'check [spec1 spec2...]', 'run the spec sampled appropriately to the associated host'
      option :samples, :type => :numeric, :default => 5, :desc => 'number of sample hosts'
      def check(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        runner = Houcho::Spec::Runner.new

        begin
          exit! unless runner.check(args, options[:samples], false, true)
        rescue SpecFileException => e
          puts e.message
          exit!
        end
      end


      desc 'exec [spec1 spec2..]', 'run spec'
      option :hosts,   :type => :array,   :desc => '--hosts host1 host2 host3...', :required => true
      option :dry_run, :type => :boolean, :default => false, :desc => 'show commands that may exexute'
      def exec(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        runner = Houcho::Spec::Runner.new

        begin
          exit! unless runner.execute_manually(
            options[:hosts],
            args,
            options[:dry_run],
            true #output to console
          )
        rescue Houcho::SpecFileException => e
          puts e.message
          exit!
        end
      end
    end
  end
end
