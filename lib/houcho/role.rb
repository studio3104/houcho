require "houcho/database"
require "houcho/host"
require "houcho/spec"
require "houcho/outerrole"
require "houcho/attribute"

module Houcho
  class RoleExistenceException < Exception; end

  class Role
    include Houcho::Attribute

    def initialize
      @db = Houcho::Database.new.handle
      @type = "role"
      @type_id = 0
    end


    def id(role)
      if role.is_a?(Regexp)
        @db.execute("SELECT id, name FROM role").map do |record|
          record[0] if record[1] =~ role
        end
      else
        @db.execute("SELECT id FROM role WHERE name = ?", role).flatten.first
      end
    end


    def name(id)
      @db.execute("SELECT name FROM role WHERE id = ?", id).flatten.first
    end


    def exist?(role)
      !id(role).nil?
    end


    def create(role)
      role = [role] unless role.is_a?(Array)

      @db.transaction do
        role.each do |r|
          begin
            @db.execute("INSERT INTO role(name) VALUES(?)", r)
          rescue SQLite3::ConstraintException, "column name is not unique"
            raise RoleExistenceException, "role already exist - #{r}"
          end
        end
      end
    end


    def delete(role)
      role = [role] unless role.is_a?(Array)

      @db.transaction do
        role.each do |r|
          raise RoleExistenceException, "role does not exist - #{r}" unless exist?(r)
          @db.execute("DELETE FROM role WHERE name = ?", r)
        end
      end
    end


    def rename(exist_role, name)
      raise RoleExistenceException, "role does not exist - #{exist_role}" unless exist?(exist_role)
      raise RoleExistenceException, "role already exist - #{name}" if exist?(name)
      @db.execute("UPDATE role SET name = '#{name}' WHERE name = '#{exist_role}'")
    end


    def list
      @db.execute("SELECT name FROM role").flatten
    end


    def details(role)
      role = role.is_a?(Array) ? role : [role]
      result = {}
      hostobj = Host.new
      specobj = Spec.new
      orobj = OuterRole.new

      role.each do |r|
        id = id(r)
        next if ! id
        id = id.is_a?(Array) ? id : [id]

        id.each do |i|
          hosts = hostobj.list(i)
          specs = specobj.list(i)
          outerroles = orobj.list(role_id: i)
          outerhosts = orobj.details(outerroles)

          tmp = {}
          tmp["host"] = hosts unless hosts.empty?
          tmp["spec"] = specs unless specs.empty?
          tmp["outer role"] = outerhosts unless outerhosts.empty?

          result[r] = tmp
        end
      end

      result
    end

    private
    def raise_target_does_not_exist(target)
      raise RoleExistenceException, "role does not exist - #{target}"
    end
  end
end
