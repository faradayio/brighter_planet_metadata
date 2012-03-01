require 'helper'

class TestFallback < Test::Unit::TestCase
  def setup
    super
    [
      'http://data.brighterplanet.com/datasets.json',
      'http://impact.brighterplanet.com/emitters.json',
      'http://certified.impact.brighterplanet.com/emitters.json',
      'http://data.brighterplanet.com/resources.json',
      'http://impact.brighterplanet.com/protocols.json',
    ].each do |url|
      WebMock.stub_request(:get, url).to_return(:status => 500)
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
  
  def test_protocols
    assert ::BrighterPlanet.metadata.protocols.values.include? 'The Climate Registry'
  end
end
