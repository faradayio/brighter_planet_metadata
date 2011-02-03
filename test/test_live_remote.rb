require 'helper'

require 'active_support/json/encoding'
require 'active_support/inflector/inflections'

class TestLiveRemoteRemote < Test::Unit::TestCase
  def setup
    super
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    {
      'http://data.brighterplanet.com/datasets.json' => %w{ LiveRemoteDataset },
      'http://data.brighterplanet.com/datasets/beta.json' => %w{ LiveRemoteBetaDataset },
      'http://carbon.brighterplanet.com/emitters.json' => %w{ LiveRemoteEmitter },
      'http://carbon.brighterplanet.com/emitters/beta.json' => %w{ LiveRemoteBetaEmitter },
      'http://certified.carbon.brighterplanet.com/emitters.json' => %w{ LiveRemoteCertifiedEmitter },
      'http://data.brighterplanet.com/resources.json' => %w{ LiveRemoteResource },
      'http://data.brighterplanet.com/resources/beta.json' => %w{ LiveRemoteBetaResource }
    }.each do |url, ary|
      FakeWeb.register_uri  :get,
                            url,
                            :status => ["200", "OK"],
                            :body => ary.to_json
    end
  end
  
  def teardown
    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end
  
  def test_refresh
    assert ::BrighterPlanet.metadata.emitters.include?('LiveRemoteEmitter')
    FakeWeb.clean_registry
    assert ::BrighterPlanet.metadata.emitters.include?('LiveRemoteEmitter') # now it's using a cache
    BrighterPlanet.metadata.refresh
    assert ::BrighterPlanet.metadata.emitters.include?('AutomobileTrip') # now it's using fallbacks
  end
  
  %w{
    datasets
    beta_datasets
    emitters
    beta_emitters
    certified_emitters
    resources
    beta_resources
  }.each do |kind|
    eval %{
      def test_#{kind}
        assert ::BrighterPlanet.metadata.#{kind}.include?('LiveRemote#{kind.camelcase.singularize}')
      end
    }
  end
end
