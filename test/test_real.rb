require 'helper'

class TestReal < Test::Unit::TestCase
  def setup
    super
    BrighterPlanet.metadata.refresh
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = true
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
    pend 'protocols.json is not on production CM1 yet'
    assert ::BrighterPlanet.metadata.protocols.values.include?('The Climate Registry')
  end
  
  def test_color
    pend 'color.json is not on production CM1 yet'
    assert %w{ red blue }.include?(::BrighterPlanet.metadata.color)
  end
end
