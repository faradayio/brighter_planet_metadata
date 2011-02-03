require 'helper'

class TestFallback < Test::Unit::TestCase
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
