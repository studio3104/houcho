# coding: utf-8
require "thor"
require "rainbow"
require "houcho/repository"

module Houcho::CLI
  class Main < Thor
    if File.exist?("#{Houcho::Config::APPROOT}/houcho.db")
      require "houcho/cli/role"
      require "houcho/cli/spec"
      require "houcho/cli/host"
      require "houcho/cli/outerrole"
      require "houcho/cli/attribute"
      register(Houcho::CLI::Role, "role", "role [create|delete|rename|list|details|exec]", "operation of roles")
      register(Houcho::CLI::Host, "host", "host [attach|detach|list|details]", "operation of hosts")
      register(Houcho::CLI::Spec, "spec", "spec [attach|detach|list|details|rename|delete|exec|check]", "operation of specs")
      register(Houcho::CLI::OuterRole, "outerrole", "outerrole [attach|detach|list|details|load]", "operation of outer roles")
      register(Houcho::CLI::Attribute, "attr", "attr [set|get|delete]", "operation of attribute")
    end

    desc "init","set houcho repository on directory set environment variable HOUCHO_ROOT"
    def init
      Houcho::Repository.init
    end

    def self.empty_args(klass, chell, mesod)
      klass.class.task_help(chell, mesod)
      exit
    end

    def self.puts_details(e, indentsize = 0, cnt = 1)
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
          if indentsize != 0
            (indentsize).times {print '   '}
          end
          title = k.to_s.color(0,255,0)
          title = '[' + k.to_s.color(219,112,147) + ']' if indentsize == 0
          puts title
          puts_details(v, indentsize+1, cnt+1)
        end
      end
    end
  end
end
