require 'helper'

class TestMemoryLeak < Test::Unit::TestCase
  def test_attack_array
    # it's possible to attack the local copy...
    local_copy = ::BrighterPlanet.metadata.emitters
    assert local_copy.include?('AutomobileTrip')
    local_copy.clear
    assert local_copy.empty?
    
    # but not me!
    assert ::BrighterPlanet.metadata.emitters.include?('AutomobileTrip')
    ::BrighterPlanet.metadata.emitters.clear
    assert ::BrighterPlanet.metadata.emitters.include?('AutomobileTrip')
  end
  
  def test_attack_strings
    # it's possible to attack the local copy, obviously...
    local_copy = ::BrighterPlanet.metadata.emitters
    assert local_copy.include?('AutomobileTrip')
    local_copy.map { |name| name.upcase! }
    assert local_copy.include?('AUTOMOBILETRIP')
    
    # but not me!
    ::BrighterPlanet.metadata.emitters.map { |name| name.upcase! }
    assert ::BrighterPlanet.metadata.emitters.include?('AutomobileTrip')
  end
end
