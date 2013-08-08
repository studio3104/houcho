require "thor"
require "rainbow"
require "houcho/host"

module Houcho::CLI
  class HostAttribute < Thor
    namespace :"host attr"
    @@h = Houcho::Host.new

    desc "set [host]", "set attribute of host"
    option :value, :type => :hash, :required => true, :desc => "assign attribute of hash"
    option :force, :type => :boolean, :desc => "update attribute if defined already"
    def set(host)
      if options[:force]
        @@h.set_attr!(host, options[:value])
      else
        @@h.set_attr(host, options[:value])
      end
#    rescue Houcho::AttributeException => e
#      puts e.message
#      exit!
    end

    desc "get [host] [attr name]", "get attribute of host"
    def get(host, name = nil)
      @@h.get_attr(host, name).each do |k,v|
        puts "#{k.to_s.color(:red)}:#{v}"
      end
    end

    desc "delete [host] [attr name]", "delete attribute of host"
    def delete(host, name = nil)
      @@h.del_attr(host, name).each do |k,v|
        print "#{k}:#{v} "
      end
    end
  end
end
