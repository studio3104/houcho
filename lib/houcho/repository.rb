require "houcho/config"

module Houcho
  class Repository
    def self.init
      [
        Houcho::Config::APPROOT,
        Houcho::Config::SPECDIR,
        Houcho::Config::SCRIPTDIR,
        Houcho::Config::OUTERROLESOURCEDIR,
        Houcho::Config::CFYAMLDIR,
        Houcho::Config::LOGDIR
      ].each do |d|
        Dir.mkdir(d) unless Dir.exist?(d)
      end

      File.write("#{Houcho::Config::FILE}", {
        "ukigumo" => { "host" => "", "port" => "" },
        "ikachan" => { "host" => "", "port" => "", "channel" => [] },
        "git" => { "uri" => "" },
        "rspec" => [],
      }.to_yaml) unless File.exist?("#{Houcho::Config::FILE}")

      File.write("#{Houcho::Config::SPECDIR}/spec_helper.rb", <<EOD
require "serverspec"
require 'pathname'
require 'net/ssh'
require "json"

include Serverspec::Helper::Ssh
include Serverspec::Helper::DetectOS
include Serverspec::Helper::Attributes

RSpec.configure do |c|
  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end

  c.ssh.close if c.ssh
  c.host  = ENV['TARGET_HOST']
  options = Net::SSH::Config.for(c.host)
  user    = options[:user] || Etc.getlogin
  c.ssh   = Net::SSH.start(c.host, user, options)

  if ENV['TARGET_HOST_ATTR']
    attr_set JSON.parse(ENV['TARGET_HOST_ATTR'], { :symbolize_names => true })
  end
end
EOD
      ) unless File.exist?("#{Houcho::Config::SPECDIR}/spec_helper.rb")
    end
  end
end
