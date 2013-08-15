require "houcho/config"
require "houcho/outerrole/save"
require "yaml"

include Houcho::OuterRole::Save

module Houcho

class OuterRole
  class CloudForecast; end
  class << CloudForecast
    def load
      cfdir = Houcho::Config::CFYAMLDIR
      @cfrole = {}

      Dir::entries(cfdir).each do |file|
        next if file !~ /\.yaml$/
        yaml = "#{cfdir}/#{file}"
        group = load_group(yaml)
        cfrole = create_cf_role(yaml, group)
        merge_cf_role(cfrole)
      end

      save_outer_role(@cfrole, "CloudForecast")
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
          hosts = (servers["hosts"] || []).map { |host| host.split(/\s+/)[1] }

          cfrole[outerrole] = hosts
        end
      end

      cfrole
    end

    def merge_cf_role(cfrole)
      cfrole.each do |role, hosts|
        @cfrole[role] = @cfrole[role] ? @cfrole[role].concat(hosts).uniq : hosts
      end
    end
  end
end

end
