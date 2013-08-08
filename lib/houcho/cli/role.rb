# -*- encoding: utf-8 -*-

require "thor"
require "houcho/role"

module Houcho
  module CLI
    class Role < Thor
      namespace :role

      # インスタンス変数にしたら各メソッドから参照される @r が nil になってしまってしたのでとりあえずでクラス変数にしてしまった
      # コンストラクタ書いてその中で @r を初期化したら、
      # ERROR: houcho role was called with arguments ["create", "target"]
      # Usage: "houcho role".
      # ってエラった。
      # Thor がサブコマンドのクラスをどう扱っているのかをちゃんと調べるなりして実装を変える。
      @@r = Houcho::Role.new

      desc 'create [role1 role2 role3...]', 'cretate role'
      def create(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        @@r.create(args)
      rescue Houcho::RoleExistenceException => e
        puts e.message
        exit!
      end

      desc 'delete [role1 role2 role3...]', 'delete a role'
      def delete(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        @@r.delete(args)
      rescue SQLite3::ConstraintException => e
        puts e.message
        exit!
      end

      desc 'rename [exist role] [name]', 'rename a role'
      def rename(exist_role, name)
        @@r.rename(exist_role, name)
      rescue SQLite3::ConstraintException, SQLite3::SQLException => e
        puts e.message
        exit!
      end

      desc 'details [role1 role2...]', 'show details about role'
      def details(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        Houcho::CLI::Main.puts_details(@@r.details(args))
      end

      desc 'list', 'show all of roles'
      def list
        puts @@r.list.join("\n")
      end

      desc 'exec (role1 role2..) [options]', 'run role'
      option :exclude_hosts, :type => :array, :desc => '--exclude-hosts host1 host2 host3...'
      option :dry_run, :type => :boolean, :default => false, :desc => 'show commands that may exexute'
      def exec(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?
        runner = Houcho::Spec::Runner.new

#        begin
          runner.execute_role(
            args,
            (options[:exclude_hosts] || []),
            options[:dry_run],
            true #output to console
          )
#        rescue
#          puts $!.message
#          exit!
#        end
      end
    end
  end
end
