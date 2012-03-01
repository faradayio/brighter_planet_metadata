require 'helper'

class TestReal < Test::Unit::TestCase
  def setup
    WebMock.disable!
    BrighterPlanet.metadata.refresh
    $old_fallback = BrighterPlanet::Metadata::FALLBACK
    silence_warnings { BrighterPlanet::Metadata.const_set 'FALLBACK', Hash.new([]) }
  end
  
  def teardown
    super
    silence_warnings { BrighterPlanet::Metadata.const_set 'FALLBACK', $old_fallback }
  end
  
  def test_emitters
    assert ::BrighterPlanet.metadata.emitters.include?('AutomobileTrip')
  end
  
  def test_resources
    assert ::BrighterPlanet.metadata.resources.include?('AutomobileMake')
  end
  
  def test_datasets
    assert ::BrighterPlanet.metadata.datasets.include?('AutomobileIndustry')
  end
  
  def test_protocols
    assert ::BrighterPlanet.metadata.protocols.values.include?('The Climate Registry')
  end
end
