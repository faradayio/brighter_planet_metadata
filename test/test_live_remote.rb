require 'helper'

class TestLiveRemote < Test::Unit::TestCase
  def setup
    super
    {
      'http://data.brighterplanet.com/datasets.json'              => { 'datasets' => %w{ LiveRemoteDataset } },
      'http://impact.brighterplanet.com/emitters.json'            => { 'emitters' => %w{ LiveRemoteEmitter } },
      'http://certified.impact.brighterplanet.com/emitters.json'  => { 'emitters' => %w{ LiveRemoteCertifiedEmitter } },
      'http://data.brighterplanet.com/resources.json'             => { 'resources' => %w{ LiveRemoteResource } },
      'http://impact.brighterplanet.com/protocols.json'           => { 'protocols' => { 'fooprotocol' => 'Foo Protocol' } },
    }.each do |url, hsh|
      WebMock.stub_request(:get, url).to_return(:status => 200, :body => MultiJson.dump(hsh))
    end
  end
    
  def test_refresh
    assert ::BrighterPlanet.metadata.emitters.include?('LiveRemoteEmitter')
    WebMock.stub_request(:get, 'http://impact.brighterplanet.com/emitters.json').to_return(:status => 200, :body => MultiJson.dump({ 'emitters' => %w{LiveRemoteRefreshedEmitter}}))

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
