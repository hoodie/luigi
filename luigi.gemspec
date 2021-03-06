# -*- encoding: utf-8 -*-
require 'rubygems' unless defined? Gem
require File.dirname(__FILE__) + "/lib/luigi/version"

Gem::Specification.new do |s|
  s.name        = "luigi"
  s.version     = Luigi::VERSION
  s.authors     = ["Hendrik Sollich"]
  s.email       = "hendrik@hoodie.de"
  s.homepage    = "https://github.com/hoodie/luigi"
  s.summary     = "luigi - a plumber"
  s.description = "A project manager that keeps track of a working directory, archive and template files.
  Used in commandline tools like ascii-invoicer."
  s.required_ruby_version     = '>= 1.9'
  s.files = Dir.glob('lib/*') + Dir.glob('lib/*/*')
  #s.extra_rdoc_files = ["README.md", "LICENSE.md"]
  s.license = 'GPL'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-core'
  s.add_development_dependency 'rake'
  s.add_runtime_dependency 'git', "~> 1.2" , ">= 1.2.8"
  s.add_runtime_dependency 'textboxes', '~> 0.0', '>= 0.0.1'
  s.add_runtime_dependency 'hashr', '~> 0.0', '>= 0.0.22'
end
