$LOAD_PATH.unshift '/Users/JP11546/Documents/houcho/lib'

require "houcho/config"
require "houcho/database"
require "yaml"

module Houcho

class OuterRole
  class CloudForecast; end
  class << CloudForecast
    def load
      cfdir = Houcho::Config::CFYAMLDIR

      Dir::entries(cfdir).each do |file|
        next if file !~ /\.yaml$/
        yaml = "#{cfdir}/#{file}"
        group = load_group(yaml)
        cfrole = create_cf_role(yaml, group)

        save_cf_role(cfrole)
      end
    end


    private
    def load_group(yaml)
      group = []

      File.open(yaml).each_line do |line|
        next unless line =~ /^---/
        if line =~ /^---\s+#(?<group>.+)\n/
          group << $~[:group].gsub(/\s+/, "_")
        else
          group << "NOGROUP"
        end
      end

      group
    end


    def create_cf_role(yaml, group)
      cfrole = {}

      YAML.load_stream(File.open(yaml)).each_with_index do |doc, i|
        label = "NOLABEL"

        doc["servers"].each do |servers|
          label = servers["label"].gsub(/\s+/, '_') if servers["label"]
          outerrole = "#{group[i]}::#{label}::#{servers["config"].sub(/\.yaml$/, "")}"
          hosts = servers["hosts"].map { |host| host.split(/\s+/)[1] }

          cfrole[outerrole] = hosts
        end
      end

      cfrole
    end


    def save_cf_role(cfrole)
      db = Houcho::DB.new.handle
      db.transaction

      cfrole.each do |outerrole, hosts|
        begin
          db.execute("INSERT INTO outerrole(name, data_source) VALUES(?,?)", outerrole, "CloudForecast")
        rescue SQLite3::ConstraintException, "column name is not unique"
        ensure
          outerrole_id = db.execute("SELECT id FROM outerrole WHERE name = ?", outerrole).flatten.first
        end

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

      db.commit
      db.close
    end
  end
end

end
