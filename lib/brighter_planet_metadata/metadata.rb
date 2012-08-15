require 'singleton'
require 'uri'
require 'net/http'
require 'multi_json'
require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/core_ext'
  require 'active_support/inflector/inflections'
end

::ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable %w{ aircraft bts_aircraft }
  inflect.uncountable 'species'
  inflect.irregular 'foot', 'feet'
  inflect.plural /(gas)\z/i, '\1es'
  inflect.singular /(gas)es\z/i, '\1'
end

module BrighterPlanet
  class Metadata
    include ::Singleton
    LIVE_URL = {
      'datasets'            => 'http://data.brighterplanet.com/datasets.json',
      'emitters'            => 'http://impact.brighterplanet.com/emitters.json',
      'certified_emitters'  => 'http://certified.impact.brighterplanet.com/emitters.json',
      'resources'           => 'http://data.brighterplanet.com/',
      'protocols'           => 'http://impact.brighterplanet.com/protocols.json',

      'automobiles_options'      => 'http://impact.brighterplanet.com/automobiles/options.json',
      'automobile_trips_options' => 'http://impact.brighterplanet.com/automobile_trips/options.json',
      'bus_trips_options'        => 'http://impact.brighterplanet.com/bus_trips/options.json',
      'computations_options'     => 'http://impact.brighterplanet.com/computations/options.json',
      'diets_options'            => 'http://impact.brighterplanet.com/diets/options.json',
      'electricity_uses_options' => 'http://impact.brighterplanet.com/electricity_uses/options.json',
      'flights_options'          => 'http://impact.brighterplanet.com/flights/options.json',
      'fuel_purchases_options'   => 'http://impact.brighterplanet.com/fuel_purchases/options.json',
      'lodgings_options'         => 'http://impact.brighterplanet.com/lodgings/options.json',
      'meetings_options'         => 'http://impact.brighterplanet.com/meetings/options.json',
      'motorcycles_options'      => 'http://impact.brighterplanet.com/motorcycles/options.json',
      'pets_options'             => 'http://impact.brighterplanet.com/pets/options.json',
      'purchases_options'        => 'http://impact.brighterplanet.com/purchases/options.json',
      'rail_trips_options'       => 'http://impact.brighterplanet.com/rail_trips/options.json',
      'residences_options'       => 'http://impact.brighterplanet.com/residences/options.json',
      'shipments_options'        => 'http://impact.brighterplanet.com/shipments/options.json',

      'automobiles_committees'      => 'http://impact.brighterplanet.com/automobiles/committees.json',
      'automobile_trips_committees' => 'http://impact.brighterplanet.com/automobile_trips/committees.json',
      'bus_trips_committees'        => 'http://impact.brighterplanet.com/bus_trips/committees.json',
      'computations_committees'     => 'http://impact.brighterplanet.com/computations/committees.json',
      'diets_committees'            => 'http://impact.brighterplanet.com/diets/committees.json',
      'electricity_uses_committees' => 'http://impact.brighterplanet.com/electricity_uses/committees.json',
      'flights_committees'          => 'http://impact.brighterplanet.com/flights/committees.json',
      'fuel_purchases_committees'   => 'http://impact.brighterplanet.com/fuel_purchases/committees.json',
      'lodgings_committees'         => 'http://impact.brighterplanet.com/lodgings/committees.json',
      'meetings_committees'         => 'http://impact.brighterplanet.com/meetings/committees.json',
      'motorcycles_committees'      => 'http://impact.brighterplanet.com/motorcycles/committees.json',
      'pets_committees'             => 'http://impact.brighterplanet.com/pets/committees.json',
      'purchases_committees'        => 'http://impact.brighterplanet.com/purchases/committees.json',
      'rail_trips_committees'       => 'http://impact.brighterplanet.com/rail_trips/committees.json',
      'residences_committees'       => 'http://impact.brighterplanet.com/residences/committees.json',
      'shipments_committees'        => 'http://impact.brighterplanet.com/shipments/committees.json',
    }.freeze

    FALLBACK = begin
      ::MultiJson.load(::File.read(::File.expand_path('../fallbacks.json', __FILE__))).freeze
    rescue
      $stderr.puts "[brighter_planet_metadata] Error while loading fallbacks. Please reinstall library."
      {}
    end
    
    # What resources are available.
    def resources
      deep_copy_of_authoritative_value_or_fallback 'resources' do |json|
        json['_embedded']['resources'].map { |r| r['name'] }
      end
    end

    # What certified_emitters are available.
    def certified_emitters
      deep_copy_of_authoritative_value_or_fallback 'certified_emitters'
    end

    # What emitters are available.
    def emitters
      deep_copy_of_authoritative_value_or_fallback 'emitters'
    end

    # What datasets are available.
    def datasets
      deep_copy_of_authoritative_value_or_fallback 'datasets'
    end
    
    # What protocols are recognized
    def protocols
      deep_copy_of_authoritative_value_or_fallback 'protocols'
    end

    # options (characteristics) available for a given emitter
    def options(emitter)
      deep_copy_of_authoritative_value_or_fallback "#{emitter.to_s.pluralize.downcase}_options"
    end

    # committees (decisions) available for a given emitter
    def committees(emitter)
      deep_copy_of_authoritative_value_or_fallback "#{emitter.to_s.pluralize.downcase}_committees"
    end
    
    # Clear out any cached values
    def refresh
      # instance_variables.each { |ivar_name| instance_variable_set ivar_name, nil }
      cache_method_clear :authoritative_value_or_fallback
    end
    
    # for cache_method
    def as_cache_key
      'BrighterPlanet::Metadata.instance'
    end
    
    private
        
    def deep_copy_of_authoritative_value_or_fallback(k, &blk)
      authoritative_value_or_fallback(k, &blk).clone
    end
    
    # Used internally to pull a live list of emitters/datasets/etc. or fall back to a static one.
    def authoritative_value_or_fallback(meta_name, &blk)
      actual = nil
      meta_name = meta_name.to_s
      if ::ENV['BRIGHTER_PLANET_METADATA_FALLBACKS_ONLY'] == 'true' && FALLBACK.key?(meta_name)
        $stderr.puts %{ENV['BRIGHTER_PLANET_METADATA_FALLBACKS_ONLY'] == 'true', so using fallback value for '#{meta_name}'}
        FALLBACK[meta_name]
      else
        value = nil
        begin
          uri = URI.parse(LIVE_URL[meta_name])
          req = Net::HTTP::Get.new(uri.request_uri)
          req['Accept'] = 'application/json'
          res = Net::HTTP.start(uri.hostname, uri.port) { |h| h.request(req) }
          unless res.is_a?(Net::HTTPSuccess)
            json = MultiJson.load res.body 
            if block_given?
              blk.call json
            else
              subkey = (meta_name == 'certified_emitters') ? 'emitters' : meta_name # the live certified response will contain an 'emitters' key
              json.key?(subkey) ? json[subkey] : json
            end
          end
        rescue ::Exception
          $stderr.puts "[brighter_planet_metadata] Rescued from #{$!.inspect} when trying to get #{meta_name}"
          $stderr.puts uri, res.body
        end
        actual || FALLBACK[meta_name]
      end
    end
    cache_method :authoritative_value_or_fallback, 60
  end
end
