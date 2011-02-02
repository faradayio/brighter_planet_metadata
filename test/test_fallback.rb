require 'helper'

class TestFallback < Test::Unit::TestCase
  def setup
    BrighterPlanet.metadata.refresh
    FakeWeb.allow_net_connect = false
  end
  
  def teardown
    FakeWeb.allow_net_connect = true
  end
  
  # because we don't have any non-beta ones yet
  def test_beta_datasets
    assert ::BrighterPlanet.metadata.beta_datasets.include? 'AutomobileIndustry'
  end
  
  def test_emitters
    assert ::BrighterPlanet.metadata.emitters.include? 'AutomobileTrip'
  end
    
  def test_resources
    assert ::BrighterPlanet.metadata.resources.include? 'AutomobileMake'
  end
end
