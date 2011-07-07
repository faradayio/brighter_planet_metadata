require 'helper'
require 'earth'

class FakeEarth
  def self.resources
    [ 'LiveData1Resource' ]
  end
end

class TestLiveData1 < Test::Unit::TestCase
  def setup
    super
    FakeFS.activate!
    
    # faking resources
    eval %{
      ::OldEarth = ::Earth
      ::Earth = ::FakeEarth
    }
    
    # faking deploy
    Rails.env = ActiveSupport::StringInquirer.new 'production'
    Rails.root = '/var/www/data1/current'
    FileUtils.mkdir_p '/var/www/data1/current/config/brighter_planet_deploy'
    FileUtils.mkdir_p '/var/www/data1/current/public/brighter_planet_deploy'
    File.open('/var/www/data1/current/config/brighter_planet_deploy/service', 'w') { |f| f.write 'ReferenceDataService' }
    
    # FAKING DATASETS
    eval "class ::Dataset; end"
    fake_dataset_path = File.join ::Rails.root, 'app', 'models', 'live_data1_dataset.rb'
    File.open(fake_dataset_path, 'w') { |f| f.write "class ::LiveData1Dataset < Dataset; end"}
    eval File.read(fake_dataset_path) unless defined?(::LiveData1Dataset)
  end
  
  def teardown
    super
    eval %{
      ::Earth = ::OldEarth
    }
  end

  def test_self_awareness
    assert ::Rails.env.production?
    assert_equal 'ReferenceDataService', ::BrighterPlanet.deploy.servers.me.service
  end
  
  def test_authority
    assert ::BrighterPlanet.metadata.send(:data1_authority).authority?('resources')
  end
  
  def test_resources
    assert_equal %w{LiveData1Resource}, ::BrighterPlanet.metadata.resources
  end
  
  def test_datasets
    assert_equal %w{LiveData1Dataset}, ::BrighterPlanet.metadata.datasets
  end

  def test_what_must_come_from_other_sources
    assert_equal ::BrighterPlanet::Metadata::FALLBACK['emitters'], ::BrighterPlanet.metadata.emitters
  end
  
  def test_inflection
    assert_equal 'GreenhouseGases', 'GreenhouseGas'.pluralize
    assert_equal 'greenhouse_gases', 'greenhouse_gas'.pluralize
    assert_equal 'GreenhouseGas', 'GreenhouseGases'.singularize
    assert_equal 'Aircraft', 'Aircraft'.pluralize
    assert_equal 'aircraft', 'aircraft'.pluralize
    assert_equal 'Aircraft', 'Aircraft'.singularize
  end
end
