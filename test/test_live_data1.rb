require 'helper'
require 'earth'

class TestLiveData1 < Test::Unit::TestCase
  def setup
    super
    # get the real gem path so we can fake it in fakefs (/usr/local/rvm/gems/ruby-1.8.7-head/gems/earth-0.3.11/lib/earth)
    earth_gem_path = ::File.dirname($LOAD_PATH.grep(/earth/)[0])
    
    FakeFS.activate!
    FileUtils.mkdir_p earth_gem_path

    # FAKING RESOURCES
    # fake earth.rb so that Gem.required_path can find it
    File.open(File.join(earth_gem_path, 'lib', 'earth.rb'), 'w') { |f| f.write "module Earth; end" }
    
    # fake what looks like a resource
    fake_resource_path = File.join earth_gem_path, 'lib', 'earth', 'live_data1_resource.rb'
    File.open(fake_resource_path, 'w') { |f| f.write "class ::LiveData1Resource < ActiveRecord::Base; end"}
    eval File.read(fake_resource_path) unless defined?(::LiveData1Resource)
        
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
