require 'fileutils'

module Houcho
  module Initialize
    templates = File.expand_path("#{File.dirname(__FILE__)}/../../templates")

    %W{conf role spec}.each do |d|
      FileUtils.cp_r("#{templates}/#{d}", d)
    end

    File.symlink('./conf/rspec.conf', './.rspec') if ! File.exists? './.rspec'
  end
end
