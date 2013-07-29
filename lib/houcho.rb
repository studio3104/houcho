require "houcho/config"

module Houcho
  [
    Houcho::Config::APPROOT,
    Houcho::Config::SPECDIR
  ].each do |d|
    Dir.mkdir(d) unless Dir.exist?(d)
  end
end
