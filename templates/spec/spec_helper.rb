require 'serverspec'
require 'pathname'
require 'net/ssh'

include Serverspec::Helper::Ssh
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end
  c.before :all do
    block = self.class.metadata[:example_group_block]
    if RUBY_VERSION.start_with?('1.8')
      file = block.to_s.match(/.*@(.*):[0-9]+>/)[1]
    else
      file = block.source_location.first
    end
    c.ssh.close if c.ssh
    c.host  = ENV['TARGET_HOST']
    options = Net::SSH::Config.for(c.host)
    user    = options[:user] || Etc.getlogin
    c.ssh   = Net::SSH.start(c.host, user, options)
    c.os    = backend(Serverspec::Commands::Base).check_os
  end
end
