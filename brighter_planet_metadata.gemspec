# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "brighter_planet_metadata/version"

Gem::Specification.new do |s|
  s.name        = "brighter_planet_metadata"
  s.version     = BrighterPlanetMetadata::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = ""
  s.summary     = %q{Names of Brighter Planet things}
  s.description = %q{What emitters (carbon models), resources (data classes), datasets, etc. we offer.}

  s.rubyforge_project = "brighter_planet_metadata"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency 'eat'
  s.add_dependency 'activesupport', '>=2.3.4'
  s.add_dependency 'i18n' # activesupport?
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'fakefs'
  s.add_development_dependency 'earth'
  unless RUBY_VERSION > '1.9'
    s.add_development_dependency 'fastercsv' # earth
  end
end
