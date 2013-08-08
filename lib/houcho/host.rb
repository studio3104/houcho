require "json"
require "houcho/element"

module Houcho
  class HostAttributeException < Exception; end

  class Host < Element
    def initialize
      super("host")
    end


    def set_attr(host, attr)
      attr.each do |name, value|
        if get_attr(host, name) != {}
          raise HostAttributeException, "attribute has defined value already - #{name}"
        end
      end

      set_attr!(host, attr)
    end


    def set_attr!(host, attr)
      set = get_attr(host).merge(attr)
      @db.execute("UPDATE host SET attributes = ? WHERE name = ?", JSON.generate(set), host)
    end


    def get_attr_json(host, name = nil)
      get_attr(host, name, true)
    end


    def get_attr(host, name = nil, json = false)
      attr_json = @db.execute("SELECT attributes FROM host WHERE name = ?", host).first.first

      return attr_json if json

      attr = JSON.parse(attr_json, { :symbolize_names => true })
      return attr.select { |k,v| k == name.to_sym } unless name.nil?
      return attr
    end


    def del_attr(host, name = nil)
      target = get_attr(host, name)
      attr = {}

      if !name.nil?
        attr = get_attr(host)
        attr.delete(name.to_sym)
      end

      @db.execute("UPDATE host SET attributes = ? WHERE name = ?", JSON.generate(attr), host)
      target
    end


    def details(hosts)
      hosts = hosts.is_a?(Array) ? hosts : [hosts]
      result  = {}

      hosts.each do |host|
        roles = super(host)[host]["role"]
        outerroles = @db.execute("
          SELECT role.name
          FROM outerrole role, outerrole_host oh
          WHERE role.id = oh.outerrole_id
          AND oh.host_id = ?
        ", id(host)).flatten.sort.uniq

        result[host] = {}
        result[host]["role"] = roles if ! roles.empty?
        result[host]["outer role"] = outerroles if ! outerroles.empty?

        result.delete(host) if result[host].keys.empty?
      end

      result
    end
  end
end
