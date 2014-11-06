# -*- encoding: utf-8 -*-
require 'rubygems' unless defined? Gem
require File.dirname(__FILE__) + "/lib/ProjectPlumber/version"

Gem::Specification.new do |s|
  s.name        = "Luigi"
  s.version     = ProjectPlumber::VERSION
  s.authors     = ["Hendrik Sollich"]
  s.email       = "hendrik@hoodie.de"
  s.homepage    = "https://github.com/hoodie/luigi"
  s.summary     = "luigi - a plumber"
  s.description = ""
  s.required_ruby_version     = '>= 2.1'
  s.files = Dir.glob('lib/*') + Dir.glob('lib/*/*')
  s.extra_rdoc_files = ["README.md", "LICENSE.md"]
  s.license = 'GPL'
  s.add_runtime_dependency 'git', "~> 1.2" , ">= 1.2.8"
end
