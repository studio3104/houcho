module Houcho
  module YamlHandle
    class Loader
      attr_reader :data

      def initialize(yaml_file)
        @data = YAML.load_file(yaml_file)
        @data ||= {}
      end
    end

    class Editor < Loader
      attr_accessor :data

      def initialize(yaml_file)
        super
        @yaml_file = yaml_file
      end

      def save_to_file
        open(@yaml_file, 'w') do |f|
          YAML.dump(@data, f)
        end
      end
    end
  end
end
