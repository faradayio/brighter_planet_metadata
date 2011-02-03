require 'helper'

class TestMemoryLeak < Test::Unit::TestCase
  def setup
    super
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri :get, 'http://carbon.brighterplanet.com/emitters.json', :status => ["500", "Urg"], :body => nil
  end
  
  def teardown
    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end
  
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
