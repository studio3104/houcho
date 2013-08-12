# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'houcho/version'

Gem::Specification.new do |spec|
  spec.name          = "houcho"
  spec.version       = Houcho::VERSION
  spec.authors       = ["Satoshi SUZUKI"]
  spec.email         = ["studio3104.com@gmail.com"]
  spec.description   = %q{covering to run serverspec}
  spec.summary       = %q{covering to run serverspec}
  spec.homepage      = "https://github.com/studio3104/houcho"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'thor'
  spec.add_runtime_dependency 'rainbow'
  spec.add_runtime_dependency 'parallel'
  spec.add_runtime_dependency 'systemu'
  spec.add_runtime_dependency 'serverspec'
  spec.add_runtime_dependency 'sqlite3-ruby'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "tmpdir"
  spec.add_development_dependency "tempfile"
end
