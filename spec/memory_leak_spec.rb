require 'helper'

describe 'memory leaks' do
  use_vcr_cassette '500 error', :record => :new_episodes
    
  it 'does not clear global metadata' do
    # it's possible to attack the local copy...
    local_copy = BrighterPlanet.metadata.emitters
    local_copy.should include('AutomobileTrip')
    local_copy.clear
    local_copy.should be_empty
    
    # but not me!
    BrighterPlanet.metadata.emitters.should include('AutomobileTrip')
    BrighterPlanet.metadata.emitters.clear
    BrighterPlanet.metadata.emitters.should include('AutomobileTrip')
  end
  
  it 'does not run in-place modifiers on global metadata' do
    # it's possible to attack the local copy, obviously...
    local_copy = BrighterPlanet.metadata.emitters
    local_copy.should include('AutomobileTrip')
    local_copy.map { |name| name.upcase! }
    local_copy.should include('AUTOMOBILETRIP')
    
    # but not me!
    BrighterPlanet.metadata.emitters.map { |name| name.upcase! }
    BrighterPlanet.metadata.emitters.should_not include('AUTOMOBILETRIP')
  end
end
