# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "addressable_savon/version"

Gem::Specification.new do |s|
  s.name        = "addressable_savon"
  s.version     = AddressableSavon::VERSION
  s.authors     = ["Indro De"]
  s.email       = ["indro.de@gmail.com"]
  s.homepage    = ""
  s.summary     = "Savon Ruby SOAP client with Addressable"
  s.description = "Ruby's heavy metal SOAP client, but using Addressable"

  s.rubyforge_project = "addressable_savon"
  
  s.add_dependency "builder",  ">= 2.1.2"
  s.add_dependency "nori",     "~> 1.0"
  s.add_dependency "httpi",    ">= 0.7.8"
  s.add_dependency "gyoku",    ">= 0.3.1" # 0.4.0
  s.add_dependency "nokogiri", ">= 1.4.1"
  s.add_dependency "addressable", ">= 2.2.6"
  
  s.add_development_dependency "rake",    "~> 0.8.7"
  s.add_development_dependency "rspec",   "~> 2.5.0"
  s.add_development_dependency "mocha",   "~> 0.9.8"
  s.add_development_dependency "timecop", "~> 0.3.5"
  s.add_development_dependency "autotest"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end