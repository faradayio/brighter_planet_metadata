require 'helper'

class TestLiveData1 < Test::Unit::TestCase
  def setup
    super
    FakeFS.activate!
    FileUtils.mkdir_p '/etc/brighterplanet'
    File.open('/etc/brighterplanet/universe', 'w') { |f| f.write 'data1_production' }
  end
  
  def teardown
    FakeFS.deactivate!
  end
  
  def test_universe
    assert_equal 'data1_production', ::BrighterPlanet.metadata.send(:universe)
  end
  
  def test_authority
    assert ::BrighterPlanet::Metadata::Data1Adapter.instance.authority?('data1_production', 'resources')
    assert ::BrighterPlanet::Metadata::Data1Adapter.instance.authority?('data1_production', 'beta_resources')
  end
  
  # def test_resources
  #   assert_equal %w{LiveData1Emitter}, ::BrighterPlanet.metadata.resources
  # end
  # 
  # def test_beta_resources
  #   assert_equal %w{LiveData1BetaEmitter}, ::BrighterPlanet.metadata.beta_resources
  # end
  # 
  # def test_certified_resources_from_fallbacks
  #   assert_equal ::BrighterPlanet::Metadata::URLS_AND_FALLBACKS['certified_resources'][1], ::BrighterPlanet.metadata.certified_resources
  # end
  # 
  # def test_certified_resources_as_though_from_certified
  #   Rails.application.certified = true
  #   assert_equal %w{LiveData1Emitter}, ::BrighterPlanet.metadata.certified_resources
  # ensure
  #   Rails.application.certified = false
  # end
end
