require 'helper'

class TestFallback < Test::Unit::TestCase
  def setup
    super
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    [
      'http://data.brighterplanet.com/datasets.json',
      'http://carbon.brighterplanet.com/emitters.json',
      'http://certified.carbon.brighterplanet.com/emitters.json',
      'http://data.brighterplanet.com/resources.json',
    ].each do |url|
      FakeWeb.register_uri  :get,
                            url,
                            :status => ["500", "Urg"],
                            :body => nil
    end
  end

  def test_emitters
    assert ::BrighterPlanet.metadata.emitters.include? 'AutomobileTrip'
  end
    
  def test_resources
    assert ::BrighterPlanet.metadata.resources.include? 'AutomobileMake'
  end
  
  def test_datasets
    assert ::BrighterPlanet.metadata.datasets.include? 'AutomobileIndustry'
  end
end
