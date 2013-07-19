module Houcho
  module CloudForecast
    module_function

    def load_yaml
      yaml_file = Tempfile.new('yaml')
      File.open(yaml_file,'a') do |t|
        Find.find('./role/cloudforecast') do |f|
          t.write File.read(f) if f =~ /\.yaml$/
        end
      end

      role_hosts = {}
      elements    = {}
      group       = []
      File.open(yaml_file) do |f|
        f.each do |l|
          if l =~ /^---/
            if l =~ /^---\s+#(.+)$/
              group << $1.gsub(/\s/, '_')
            else
              group << 'NOGROUPNAME'
            end
          end
        end
      end
      File.open(yaml_file) do |f|
        i=0
        YAML.load_documents(f) do |data|
          elements[group[i]] ||= []
          elements[group[i]].concat data['servers']
          i+=1
        end
      end

      elements.each do |groupname, data|
        current_label = 'NOCATEGORYNAME'

        data.each do |d|
          if ! d['label'].nil?
            label = d['label'].gsub(/\s/, '_')
            current_label = label if current_label != label
          end

          d['hosts'].map! do |host|
            host = host.split(' ')
            host = host.size == 1 ? host[0] : host[1]
          end

          r = groupname + '::' + current_label + '::' + d['config'].sub(/\.yaml$/, '')
          ary = (role_hosts[r] || []) | d['hosts']
          role_hosts[r] = ary.uniq
        end
      end

      File.write('./role/cloudforecast.yaml', role_hosts.to_yaml)
    end
  end
end
