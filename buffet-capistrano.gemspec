# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "buffet/capistrano/version"

Gem::Specification.new do |s|
  s.name        = "buffet-capistrano"
  s.version     = Buffet::Capistrano::VERSION
  s.authors     = ["bondarev"]
  s.email       = ["alexander.i.bondarev@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Capistrano support for remote testing}
  s.description = %q{Adds buffet:prepare task to capistrano}

  s.rubyforge_project = "buffet-capistrano"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "capistrano"
  s.add_dependency "buffet-gem", ">=1.2"
  s.add_dependency "rvm"
  s.add_dependency "rvm-capistrano"

  s.add_development_dependency "rspec"
end
