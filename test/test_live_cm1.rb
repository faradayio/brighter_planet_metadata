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
    Rails.env = ActiveSupport::StringInquirer.new 'production'
    Rails.root = '/data/edge/current'
    FileUtils.mkdir_p '/data/edge/current/config/brighter_planet_deploy'
    FileUtils.mkdir_p '/data/edge/current/public/brighter_planet_deploy'
    File.open('/data/edge/current/config/brighter_planet_deploy/service', 'w') { |f| f.write 'EmissionEstimateService' }
  end
    
  def test_self_awareness
    assert ::Rails.env.production?
    assert_equal 'EmissionEstimateService', ::BrighterPlanet.deploy.servers.me.service
  end
  
  def test_authority
    assert ::BrighterPlanet::Metadata::Cm1Authority.instance.authority?('emitters')

    # you don't have authority to say what's certified...
    assert !::BrighterPlanet::Metadata::Cm1Authority.instance.authority?('certified_emitters')
    
    # now you do
    Rails.application.certified = true
    assert ::BrighterPlanet::Metadata::Cm1Authority.instance.authority?('certified_emitters')
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
