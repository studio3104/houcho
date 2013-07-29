# -*- encoding: utf-8 -*-
require 'net/http'
require 'uri'

module Houcho
  module CI
  end
end

module Houcho::CI
  class UkigumoClient
    def initialize(server, port = 80, url = "http://#{server}:#{port}")
      @ukigumo_server = server
      @ukigumo_listen_port = port
      @ukigumo_base_url = url
    end

    def search(elements, limit = 1)
      query_string = URI.encode_www_form({
        :project  => elements[:project].to_s,
        :branch   => elements[:branch].to_s,
        :revision => elements[:revision].to_s,
        :limit    => limit.to_s,
      })

      Net::HTTP.start(@ukigumo_server, @ukigumo_listen_port) do |http|
        responce = http.get("/api/v1/report/search?#{query_string}")
        responce.body
      end
    end

    def post(elements)
      response = Net::HTTP.post_form(
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
      )
      response.body
    end
  end

  class IkachanClient
    def initialize(channel, server, port = 4979)
      @ikachan_server = server
      @ikachan_listen_port = port
      @ikachan_channels = channel.is_a?(Array) ? channel : [channel]
    end

    # return が @ikachan_channels の最後の要素だけになってるからどうにかする
    def post(message)
      @ikachan_channels.each do |channel|
        response = Net::HTTP.post_form(
          URI.parse("http://#{@ikachan_server}:#{@ikachan_listen_port}/notice"),
          {
            :channel => channel,
            :message => message,
          }
        )
        response.body
      end
    end
  end
end
