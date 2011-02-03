require 'helper'

class TestDeveloperMachine < Test::Unit::TestCase
  def test_developing_cm1_locally
    ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE'] = 'cm1_production'
    assert_equal 'cm1_production', BrighterPlanet.metadata.send(:universe)
  ensure 
    ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE'] = ''
  end
  
  def test_developing_data1_locally
    ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE'] = 'data1_production'
    assert_equal 'data1_production', BrighterPlanet.metadata.send(:universe)
  ensure 
    ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE'] = ''
  end
end
