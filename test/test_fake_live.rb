require 'helper'

require 'fakeweb'
require 'active_support/json/encoding'
require 'active_support/inflector/inflections'

class TestFakeLive < Test::Unit::TestCase
  def setup
    BrighterPlanet.metadata.refresh
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    {
      'http://data.brighterplanet.com/datasets.json' => %w{ FakeLiveDataset },
      'http://data.brighterplanet.com/datasets/beta.json' => %w{ FakeLiveBetaDataset },
      'http://carbon.brighterplanet.com/emitters.json' => %w{ FakeLiveEmitter },
      'http://carbon.brighterplanet.com/emitters/beta.json' => %w{ FakeLiveBetaEmitter },
      'http://certified.carbon.brighterplanet.com/emitters.json' => %w{ FakeLiveCertifiedEmitter },
      'http://data.brighterplanet.com/resources.json' => %w{ FakeLiveResource },
      'http://data.brighterplanet.com/resources/beta.json' => %w{ FakeLiveBetaResource }
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
    assert ::BrighterPlanet.metadata.emitters.include?('FakeLiveEmitter')
    FakeWeb.clean_registry
    assert ::BrighterPlanet.metadata.emitters.include?('FakeLiveEmitter') # now it's using a cache
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
        assert ::BrighterPlanet.metadata.#{kind}.include?('FakeLive#{kind.camelcase.singularize}')
      end
    }
  end
end
