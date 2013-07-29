# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

require 'houcho/role'
require "houcho/database"

module Houcho
  class RoleExistenceException < Exception; end

  class Element
    def initialize(table)
      @db = Houcho::DB.new
      @role = Houcho::Role.new
      @table = table
    end


    def list(id = nil)
      sql = "SELECT name FROM #{@table}"
      sql += " WHERE role_id = #{id}" if id

      @db.handle.execute(sql)
    end


    def details(elements)
      # とんでもないメソッドチェーンになってるので直す
      result = {}
      elements.each do |element|
        result[element] = {
          'role' =>
          @db.handle.execute("SELECT role_id FROM #{@table} WHERE name = '#{element}'").flatten.map do |id|
            @db.handle.execute("SELECT name FROM role WHERE id = '#{id}'")
          end.flatten
        }
      end
      result
    end


    def attached?(element, id = nil)
      sql = "SELECT * FROM #{@table} WHERE name = '#{element}'"
      sql += " AND role_id = #{id}" if id

      !@db.handle.execute(sql).empty?
    end


    def attach(elements, roles)
      elements = [elements] unless elements.is_a?(Array)
      roles = [roles] unless roles.is_a?(Array)

      roles.each do |role|
        id = @role.id(role).flatten.first
        raise RoleExistenceException, "Role has not been defined. - #{role}" if id.nil?

        @db.handle.transaction do
          elements.each do |element|
            # id と element で UNIQUE 制約してるけど、それの違反は無視して next でいいかな、と思いました。
            begin
              @db.handle.execute("INSERT INTO #{@table} VALUES(#{id}, '#{element}')")
            rescue SQLite3::ConstraintException
              next
            end
          end
        end
      end
    end


    def detach(elements, roles)
      elements = [elements] unless elements.is_a?(Array)
      roles = [roles] unless roles.is_a?(Array)

      roles.each do |role|
        id = @role.id(role).flatten.first
        raise RoleExistenceException, "Role has not been defined. - #{role}" if id.nil?

        @db.handle.transaction do
          elements.each do |element|
            # DELETE 対象が存在しなかったときにエラるようにすべきか？
            @db.handle.execute("DELETE FROM #{@table} WHERE role_id = #{id} AND name = '#{element}'")
          end
        end
      end
    end
  end
end

__END__
    def indexes(element)
      return [] if ! @elements.data.values.flatten.include?(element)
      @elements.data.select { |index, elems| elems.include?(element) }.keys
    end


  end
end
