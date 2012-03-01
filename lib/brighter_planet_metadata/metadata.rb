require 'singleton'
require 'eat'
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
      'resources'           => 'http://data.brighterplanet.com/resources.json',
      'protocols'           => 'http://impact.brighterplanet.com/protocols.json',
    }.freeze
    
    # sabshere 2/4/11 obv these have to be updated with some regularity
    FALLBACK = {
      'datasets'            => %w{ AutomobileIndustry FlightIndustry },
      'emitters'            => %w{ Automobile AutomobileTrip BusTrip Computation Diet ElectricityUse Flight FuelPurchase Lodging Meeting Motorcycle Pet Purchase RailTrip Residence Shipment },
      'certified_emitters'  => %w{ },
      'resources'           => %w{ AirConditionerUse Aircraft AircraftClass AircraftFuelUseEquation Airline Airport AutomobileFuel AutomobileMake AutomobileMakeFleetYear AutomobileMakeModel AutomobileMakeModelYear AutomobileMakeModelYearVariant AutomobileMakeYear AutomobileSizeClass AutomobileSizeClassYear AutomobileTypeFuelAge AutomobileTypeFuelControl AutomobileTypeFuelYear AutomobileTypeFuelYearAge AutomobileTypeFuelYearControl AutomobileTypeYear Breed BreedGender BtsAircraft BusClass BusFuel BusFuelControl BusFuelYearControl Carrier CarrierMode CensusDivision CensusRegion ClimateDivision ClothesMachineUse ComputationCarrier ComputationCarrierInstanceClass ComputationCarrierRegion Country DietClass DishwasherUse EgridRegion EgridSubregion FlightDistanceClass FlightSeatClass FlightSegment FoodGroup Fuel FuelPrice FuelType FuelYear Gender GreenhouseGas LodgingClass PetroleumAdministrationForDefenseDistrict RailClass ResidenceAppliance ResidenceClass ResidenceFuelPrice ResidenceFuelType ResidentialEnergyConsumptionSurveyResponse ShipmentMode Species State Urbanity ZipCode },
      'protocols'           => { 'ghg_protocol_scope_3' => 'Greenhouse Gas Protocol Scope 3', 'iso' => 'ISO 14064-1', 'tcr' => 'The Climate Registry', 'ghg_protocol_scope_1' => 'Greenhouse Gas Protocol Scope 1' },
    }.freeze
    
    # What resources are available.
    def resources
      deep_copy_of_authoritative_value_or_fallback 'resources'
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
        
    def deep_copy_of_authoritative_value_or_fallback(k)
      authoritative_value_or_fallback(k).clone
    end
    
    # Used internally to pull a live list of emitters/datasets/etc. or fall back to a static one.
    def authoritative_value_or_fallback(k)
      k = k.to_s
      if ::ENV['BRIGHTER_PLANET_METADATA_FALLBACKS_ONLY'] == 'true'
        $stderr.puts %{ENV['BRIGHTER_PLANET_METADATA_FALLBACKS_ONLY'] == 'true', so using fallback value for '#{k}'}
        FALLBACK[k]
      else
        begin
          hsh = ::MultiJson.decode eat(LIVE_URL[k])
          kk = (k == 'certified_emitters') ? 'emitters' : k # the live certified response will contain an 'emitters' key
          raise unless hsh.has_key? kk
          hsh[kk]
        rescue ::Exception
          FALLBACK[k]
        end
      end
    end
    cache_method :authoritative_value_or_fallback, 60
  end
end
