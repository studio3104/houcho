require "houcho/database"

module Houcho
  class AttributeExceptiotn < Exception; end

  module Attribute
    def attr_id(attr_name)
      id = @db.execute("SELECT id FROM attribute WHERE name = ?", attr_name)
      raise AttributeExceptiotn, "attribute does not exist - #{attr_name}" unless id
      id.flatten.first
    end


    def set_attr!(target, attr)
      set_attr(target, attr, true)
    end

    def set_attr(target, attr, force = false)
      target_id = id(target)
      raise_target_does_not_exist(target) if target_id.nil?
      @db.transaction do

      attr.each do |name, attr_value|
        attr_name = name.to_s

        begin
          @db.execute("INSERT INTO attribute(name) VALUES(?)", attr_name)
        rescue SQLite3::ConstraintException, "column name is not unique"
        end

        begin
          @db.execute(
            "INSERT INTO attribute_value(attr_id, element_type, element_id, value) VALUES(?,?,?,?)",
            attr_id(attr_name),
            @type_id,
            target_id,
            attr_value
          )
        rescue SQLite3::ConstraintException, "columns attr_id, element_type, element_id are not unique"
          if force
            @db.execute("
              UPDATE attribute_value SET value = ?
              WHERE attr_id = ? AND element_type = ? AND element_id = ?
            ", attr_value, attr_id(attr_name), @type_id, target_id)
          else
            raise AttributeExceptiotn, "attribute has already defined value in #{@type} - #{attr_name}"
          end
        end
      end

      end #end of transaction
    end


    def get_attr_json(target, name = nil)
      get_attr(target, name, true)
    end


    def get_attr(target, attr_name = nil, json = false)
      target_id = id(target)
      return json ? "{}" : {} if target_id.nil?
      attr = {}

      id_value = @db.execute("
        SELECT attr_id, value FROM attribute_value
        WHERE element_type = ? AND element_id = ?
      ", @type_id, target_id)

      id_value.each do |iv|
        name = @db.execute("SELECT name FROM attribute WHERE id = ?", iv[0]).first.first
        attr[name.to_sym] = iv[1]
      end

      attr = attr.select { |k,v| k == attr_name.to_sym } if attr_name
      attr = JSON.generate(attr) if json
      attr
    end


    def del_attr(target, attr_name = nil)
      before_delete = get_attr(target, attr_name)
      sql = "DELETE FROM attribute_value WHERE element_type = ? AND element_id = ?"

      @db.transaction do

      if attr_name
        sql += " AND attr_id = ?"
        @db.execute(sql, @type_id, id(target), attr_id(attr_name))
      else
        @db.execute(sql, @type_id, id(target))
      end

      end #end of transaction

      before_delete
    end
  end
end
