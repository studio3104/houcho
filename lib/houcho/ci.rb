require 'net/http'
require 'uri'

module Houcho
  module CI
  end
end

module Houcho::CI
  class UkigumoClient
    def initialize(server, port = 80, url = "http://#{server}:#{port}")
      @ukigumo_server      = server
      @ukigumo_listen_port = port
      @ukigumo_base_url    = url
    end

    def search(elements, limit = 1)
      query_string = 
        URI.encode("project")  + "=" + URI.encode(elements[:project].to_s)  + "&" +
        URI.encode("branch")   + "=" + URI.encode(elements[:branch].to_s)   + "&" +
        URI.encode("revision") + "=" + URI.encode(elements[:revision].to_s) + "&" +
        URI.encode("limit")    + "=" + URI.encode(limit.to_s)

      Net::HTTP.start(@ukigumo_server, @ukigumo_listen_port) do |http|
        responce = http.get("/api/v1/report/search?#{query_string}")
        responce.body
      end
    end

    def post(elements)
      Net::HTTP.post_form(
        URI.parse("#{@ukigumo_base_url}/api/v1/report/add"),
        {
          :status   => elements[:status],
          :project  => elements[:project],
          :branch   => elements[:branch],
          :repo     => elements[:repo],
          :revision => elements[:revision],
          :vc_log   => elements[:vc_log],
          :body     => elements[:body],
        }
      ).body
    end
  end

  class IkachanClient
    def initialize(channel, server, port = 4979)
      @ikachan_server      = server
      @ikachan_listen_port = port
      @ikachan_channels    = channel.instance_of?(Array) ? channel : [channel]
    end

    def post(message)
      @ikachan_channels.each do |channel|
        Net::HTTP.post_form(
          URI.parse("http://#{@ikachan_server}:#{@ikachan_listen_port}/notice"),
          {
            :channel => channel,
            :message => message,
          }
        ).body
      end
    end
  end
end
