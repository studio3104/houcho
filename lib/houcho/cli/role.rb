# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

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
      # Houcho::Role を特異クラスにするとかだとなんか違うし。
      # Thor がサブコマンドのクラスをどう扱っているのかをちゃんと調べるなりして実装を変える。
      @@r = Houcho::Role.new

      desc 'create [role1 role2 role3...]', 'cretate role'
      def create(*args)
        @@r.create(args)
      rescue SQLite3::ConstraintException => e
        puts e.message
        exit!
      end

      desc 'delete [role1 role2 role3...]', 'delete a role'
      def delete(*args)
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
    end
  end
end

__END__

      desc 'details [role1 role2...]', 'show details about role'
      def details(*args)
        Helper.empty_args(self, shell, __method__) if args.empty?
        Houcho::Console.puts_details(Houcho::Role.details(args))
      end

      desc 'show', 'show all of roles'
      def show
        puts Houcho::Role.all.join("\n")
      end

      desc 'exec (role1 role2..) [options]', 'run role'
      option :exclude_hosts, :type => :array, :desc => '--exclude-hosts host1 host2 host3...'
      option :ukigumo, :type => :boolean, :desc => 'post results to UkigumoServer'
      option :ikachan, :type => :boolean, :desc => 'post fail results to Ikachan'
      option :dry_run, :type => :boolean, :desc => 'show commands that may exexute'
      def exec(*args)
        Helper.empty_args(self, shell, __method__) if args.empty?

        begin
          messages = Houcho::Spec::Runner.exec(
            args, (options[:exclude_hosts] || []), [], [],
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
  end
end
