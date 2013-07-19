#!/usr/bin/env ruby
require 'yaml'
File.write('./conf', {
  'ukigumo' => {
    'host' => nil,
    'port' => nil,
  },
  'ikachan' => {
    'host' => nil,
    'port' => nil,
    'channel' => [],
  },
  'git' => {'uri' => nil}
}.to_yaml)
