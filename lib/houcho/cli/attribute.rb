require "thor"
require "houcho/attribute"

module Houcho
  module CLI
    class Attribute < Thor
      namespace :attr


      def self.target_type_obj(target_type)
        case target_type
        when "role"
          Houcho::Role.new
        when "outerrole"
          Houcho::OuterRole.new
        when "host"
          Houcho::Host.new
        else
          Houcho::CLI::Main.empty_args(self, shell, __method__)
          # puts helps and exit(1)
        end
      end


      desc "set [key1:value1 key2:value2...]", "set attribute"
      option :target, :type => :hash, :required => true, :desc => "assign target of hash"
      option :force, :type => :boolean, :desc => "update attribute if defined already"
      def set(*args)
        Houcho::CLI::Main.empty_args(self, shell, __method__) if args.empty?

        value = {}
        args.each do |v|
          value = value.merge(Hash[*v.split(":")])
        end

        options[:target].each do |target_type, target_name|
          obj = Houcho::CLI::Attribute.target_type_obj(target_type)
          begin
            if options[:force]
              obj.set_attr!(target_name, value)
            else
              obj.set_attr(target_name, value)
            end
          rescue Houcho::AttributeExceptiotn => e
            puts e.message
            exit!
          end
        end
      end


      desc "get [attr name](optional)", "get attribute"
      option :target, :type => :hash, :required => true, :desc => "assign target of hash"
      def get(attr_name = nil)
        options[:target].each do |target_type, target_name|
          obj = Houcho::CLI::Attribute.target_type_obj(target_type)
          obj.get_attr(target_name, attr_name).each do |k,v|
            puts "#{k.to_s.color(:red)}:#{v}"
          end
        end
      end


      desc "delete [attr name](optional)", "delete attribute of host"
      option :target, :type => :hash, :required => true, :desc => "assign target of hash"
      def delete(attr_name = nil)
        options[:target].each do |target_type, target_name|
          obj = Houcho::CLI::Attribute.target_type_obj(target_type)
          obj.del_attr(target_name, attr_name).each do |k,v|
            print "#{k}:#{v} "
          end
        end
      end
    end
  end
end
