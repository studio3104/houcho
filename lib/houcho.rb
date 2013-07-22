# -*- encoding: utf-8 -*-
require 'fileutils'
require 'rainbow'
require 'systemu'
require 'tempfile'
require 'find'
require 'yaml'
require 'json'
require 'houcho/yamlhandle'
require 'houcho/element'
require 'houcho/role'
require 'houcho/host'
require 'houcho/spec'
require 'houcho/spec/runner'
require 'houcho/cloudforecast'
require 'houcho/cloudforecast/role'
require 'houcho/cloudforecast/host'
require 'houcho/ci'

module Houcho
  def init_repo
    templates = File.expand_path("#{File.dirname(__FILE__)}/../templates")

    %W{conf role spec}.each do |d|
      FileUtils.cp_r("#{templates}/#{d}", d) if ! Dir.exist?(d)
    end

    File.symlink('./conf/rspec.conf', './.rspec') if ! File.exists? '.rspec'

    `git init; git add .; git commit -a -m 'initialized houcho repository'` if ! Dir.exist?('.git')
  end


  def puts_details(e, indentsize = 0, cnt = 1)
    case e
    when Array
      e.sort.each.with_index(1) do |v, i|
        (indentsize-1).times {print '   '}
        print i != e.size ? '├─ ' : '└─ '
        puts v
      end
      puts ''
    when Hash
      e.each do |k,v|
        if ! indentsize.zero?
          (indentsize).times {print '   '}
        end
        k = k.color(0,255,0)
        k = '[' + k.color(219,112,147) + ']' if indentsize.zero?
        puts k
        puts_details(v, indentsize+1, cnt+1)
      end
    end
  end
end
