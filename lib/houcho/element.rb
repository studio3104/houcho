require 'houcho/role'
require "houcho/database"

module Houcho
  class Element
    def initialize(type)
      @db = Houcho::Database::Handle
      @role = Houcho::Role.new
      @type = type
    end


    def id(name)
      @db.execute("SELECT id FROM #{@type} WHERE name = '#{name}'").flatten.first
    end


    def list(role_id = nil)
      sql = "SELECT T1.name FROM #{@type} T1"
      sql += " JOIN role_#{@type} T2 ON T1.id = T2.#{@type}_id WHERE T2.role_id = #{role_id}" if role_id

      @db.execute(sql).flatten
    end


    def details(elements)
      elements = elements.is_a?(Array) ? elements : [elements]
      result = {}

      elements.each do |element|
        roles = @db.execute("
          SELECT role.name
          FROM role, #{@type}, role_#{@type}
          WHERE role_#{@type}.#{@type}_id = #{@type}.id
          AND role_#{@type}.role_id = role.id
          AND #{@type}.name = ?
        ", element).flatten.sort.uniq

        result[element] = { "role" => roles }
      end

      result
    end


    def attach(elements, roles)
      elements = [elements] unless elements.is_a?(Array)
      roles = [roles] unless roles.is_a?(Array)

      roles.each do |role|
        role_id = @role.id(role)
        raise RoleExistenceException, "role does not exist - #{role}" unless role_id

        @db.transaction do

        elements.each do |element|
          @db.execute("INSERT INTO #{@type}(name) VALUES(?)", element) unless id(element)

          begin
            @db.execute("INSERT INTO role_#{@type} VALUES(?,?)", role_id, id(element))
          rescue SQLite3::ConstraintException
            next
          end
        end

        end #end of transaction
      end
    end


    def detach_from_all(elements)
      roles = []
      details(elements).each do |e, r|
        roles = roles.concat(r["role"]||[]).uniq
      end

      detach(elements, roles)
    end


    def detach(elements, roles)
      elements = [elements] unless elements.is_a?(Array)
      roles = [roles] unless roles.is_a?(Array)

      roles.each do |role|
        role_id = @role.id(role)
        raise RoleExistenceException, "role does not exist - #{role}" if role_id.nil?

        @db.transaction do

        elements.each do |element|
          @db.execute(
            "DELETE FROM role_#{@type} WHERE role_id = ? AND #{@type}_id = ?",
            role_id,
            id(element)
          )

          begin
            @db.execute("DELETE FROM #{@type} WHERE name = ?", element)
          rescue SQLite3::ConstraintException, "foreign key constraint failed"
            next
          end
        end

        end #end of transaction
      end
    end
  end
end
