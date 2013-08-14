require "houcho/config"
require "houcho/outerrole/save"
require "net/http"
require "cgi"
require "json"

include Houcho::OuterRole::Save

module Houcho

class OuterRole
  class Yabitz; end
  class << Yabitz
    def load
      begin
        yabitz = YAML.load_file(Houcho::Config::FILE)["yabitz"]
      rescue
      end

      if yabitz
        yabitzrole = create_yabitz_role(yabitz["host"], yabitz["port"])
        save_outer_role(yabitzrole, "Yabitz")
      end
    end


    private
    def http_get(host, port, path, params)
      Net::HTTP.get(
        host,
        "#{path}?".concat(
          params.collect do |k,v|
            "#{k}=#{CGI::escape(v.to_s)}"
          end.join("&")
        ),
        port
      )
    end

    def download_json(host, port)
      JSON.load(
        http_get(
          host, port, "/ybz/search.json",
          {
            andor: "AND",
            cond0: 0,
            field0: "os",
            value0: " ",
            status: "IN_SERVICE",
            ex_andor: "AND",
            ex_cond0: 0,
            ex_field0: "not_selected",
            ex_value0: nil,
          },
        )
      )
    end

    def create_yabitz_role(host, port)
      data = {}

      download_json(host, port).each do |instance|
        host = instance["display"]
        type = instance["content"]["type"]
        hw = instance["content"]["hwinfo"]
        os = instance["content"]["os"]

        type = type ? type.gsub(/\s+/, "") : "NOTYPEINFO"
        hw = hw ? hw.gsub(/\s+/, "") : "NOHWINFO"
        os = os ? os.gsub(/\s+/, "") : "NOOSINFO"

        role = "#{type}::#{hw}::#{os}"
        data[role] ||= []
        data[role].concat([instance["display"]]).uniq
      end

      data
    end
  end
end

end
