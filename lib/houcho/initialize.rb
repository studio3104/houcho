require 'fileutils'

module Houcho
  module Initialize
    templates = File.expand_path("#{File.dirname(__FILE__)}/../../templates")

    %W{conf role spec}.each do |d|
      FileUtils.cp_r("#{templates}/#{d}", d) if ! Dir.exist?(d)
    end

    File.symlink('./conf/rspec.conf', './.rspec') if ! File.exists? '.rspec'

    `git init; git add .; git commit -a -m 'initialized houcho repository'` if ! Dir.exist?('.git')
  end
end
