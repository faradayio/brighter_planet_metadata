require 'helper'

module BrighterPlanet
  module Emitter
  end
  module LiveCm1Emitter
    extend BrighterPlanet::Emitter
  end
end

class TestLiveCm1 < Test::Unit::TestCase
  def setup
    super
    FakeFS.activate!
    FileUtils.mkdir_p '/etc/brighterplanet'
    File.open('/etc/brighterplanet/universe', 'w') { |f| f.write 'cm1_production' }
  end
    
  def test_universe
    assert_equal 'cm1_production', ::BrighterPlanet.metadata.send(:universe)
  end
  
  def test_authority
    assert ::BrighterPlanet::Metadata::Cm1Adapter.instance.authority?('cm1_production', 'emitters')

    # you don't have authority to say what's certified...
    assert !::BrighterPlanet::Metadata::Cm1Adapter.instance.authority?('cm1_production', 'certified_emitters')
    
    # now you do
    Rails.application.certified = true
    assert ::BrighterPlanet::Metadata::Cm1Adapter.instance.authority?('cm1_production', 'certified_emitters')
  ensure
    Rails.application.certified = false
  end
  
  def test_emitters
    assert_equal %w{LiveCm1Emitter}, ::BrighterPlanet.metadata.emitters
  end
  
  def test_what_must_come_from_other_sources
    assert_equal ::BrighterPlanet::Metadata::FALLBACK['resources'], ::BrighterPlanet.metadata.resources
  end

  # note: you still get a list of certified emitters! the point is that you, as the edge server, don't decide which ones they are
  # in other words, nothing is ever certified unless Rails.application.certified?
  def test_certified_emitters_as_if_on_edge
    assert_equal ::BrighterPlanet::Metadata::FALLBACK['certified_emitters'], ::BrighterPlanet.metadata.certified_emitters
  end
  
  def test_certified_emitters_as_if_on_certified
    Rails.application.certified = true
    assert_equal %w{LiveCm1Emitter}, ::BrighterPlanet.metadata.certified_emitters
  ensure
    Rails.application.certified = false
  end
end
