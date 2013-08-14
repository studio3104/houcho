require "houcho/database"

module Houcho

class OuterRole
  module Save
    def save_outer_role(outerrole, datasource)
      db = Houcho::Database.new.handle
      db.transaction do

      delete_ids = db.execute("SELECT id FROM outerrole WHERE data_source = ?", datasource).flatten

      outerrole.each do |outerrole, hosts|
        begin
          db.execute("INSERT INTO outerrole(name, data_source) VALUES(?,?)", outerrole, datasource)
        rescue SQLite3::ConstraintException, "column name is not unique"
        ensure
          outerrole_id = db.execute("SELECT id FROM outerrole WHERE name = ?", outerrole).flatten.first
        end

        delete_ids.delete(outerrole_id)
        db.execute("DELETE FROM outerrole_host WHERE outerrole_id = ?", outerrole_id)

        hosts.each do |host|
          begin
            db.execute("INSERT INTO host(name) VALUES(?)", host)
          rescue SQLite3::ConstraintException, "column name is not unique"
          ensure
            begin
              db.execute(
                "INSERT INTO outerrole_host(outerrole_id, host_id) VALUES(?,?)",
                outerrole_id,
                db.execute("SELECT id FROM host WHERE name = ?", host).flatten.first
              )
            rescue SQLite3::ConstraintException, "column name is not unique"
            end
          end
        end
      end

      delete_ids.each do |id|
        db.execute("DELETE FROM outerrole_host WHERE outerrole_id = ?", id)
      end

      end #end of transaction
    end
  end
end

end
