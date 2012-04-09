require 'helper'

class TestFallback < Test::Unit::TestCase
  def setup
    super
    [
      %r{http.*brighterplanet.com.*}
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

  def test_options_flight
    assert ::BrighterPlanet.metadata.options(:flight).include?('origin_airport')
  end

  def test_options_electricity_use
    assert ::BrighterPlanet.metadata.options(:electricity_use).include?('zip_code')
  end

  def test_committees_flight
    assert ::BrighterPlanet.metadata.committees(:flight).include?('energy')
  end
end
