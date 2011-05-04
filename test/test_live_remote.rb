require 'helper'

require 'active_support/json/encoding'
require 'active_support/inflector/inflections'

class TestLiveRemote < Test::Unit::TestCase
  def setup
    super
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    {
      'http://data.brighterplanet.com/datasets.json'              => { 'datasets' => %w{ LiveRemoteDataset } },
      'http://carbon.brighterplanet.com/emitters.json'            => { 'emitters' => %w{ LiveRemoteEmitter } },
      'http://certified.carbon.brighterplanet.com/emitters.json'  => { 'emitters' => %w{ LiveRemoteCertifiedEmitter } },
      'http://data.brighterplanet.com/resources.json'             => { 'resources' => %w{ LiveRemoteResource } },
      'http://carbon.brighterplanet.com/protocols.json'           => { 'protocols' => { 'fooprotocol' => 'Foo Protocol' } },
    }.each do |url, hsh|
      FakeWeb.register_uri  :get,
                            url,
                            :status => ["200", "OK"],
                            :body => hsh.to_json
    end
  end
    
  def test_refresh
    assert ::BrighterPlanet.metadata.emitters.include?('LiveRemoteEmitter')
    FakeWeb.register_uri :get, 'http://carbon.brighterplanet.com/emitters.json', :status => ["200", "OK"], :body => { 'emitters' => %w{LiveRemoteRefreshedEmitter}}.to_json

    # still the old value because it's cached...
    assert ::BrighterPlanet.metadata.emitters.include?('LiveRemoteEmitter')

    BrighterPlanet.metadata.refresh
    assert ::BrighterPlanet.metadata.emitters.include?('LiveRemoteRefreshedEmitter')
  end
  
  %w{
    datasets
    emitters
    certified_emitters
    resources
  }.each do |kind|
    eval %{
      def test_#{kind}
        assert ::BrighterPlanet.metadata.#{kind}.include?('LiveRemote#{kind.camelcase.singularize}')
      end
    }
  end
  
  def test_protocols
    assert ::BrighterPlanet.metadata.protocols.values.include?('Foo Protocol')
  end
end
