require "houcho/element"
require "houcho/attribute"

module Houcho
  class HostExistenceException < Exception; end

  class Host < Element
    include Houcho::Attribute

    def initialize
      super("host")
      @type_id = 2
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

    private
    def raise_target_does_not_exist(target)
      raise HostExistenceException, "host does not exist - #{target}"
    end
  end
end
