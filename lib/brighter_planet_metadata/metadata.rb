require 'singleton'
require 'eat'
require 'active_support'
require 'active_support/version'
%w{
  active_support/json
  active_support/core_ext/object/blank
  active_support/inflector/inflections
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3

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
      'emitters'            => 'http://carbon.brighterplanet.com/emitters.json',
      'certified_emitters'  => 'http://certified.carbon.brighterplanet.com/emitters.json',
      'resources'           => 'http://data.brighterplanet.com/resources.json',
      'protocols'           => 'http://carbon.brighterplanet.com/protocols.json',
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
      clear_method_cache :authoritative_value_or_fallback
    end
    
    # for cache_method
    HASH = 'BrighterPlanet::Metadata.instance'.hash
    def method_cache_hash
      HASH
    end
    
    private
    
    autoload :Cm1Authority, 'brighter_planet_metadata/cm1_authority'
    def cm1_authority
      Cm1Authority.instance
    end
    
    autoload :Data1Authority, 'brighter_planet_metadata/data1_authority'
    def data1_authority
      Data1Authority.instance
    end
    
    def authorities
      [ cm1_authority, data1_authority ]
    end
    
    def deep_copy_of_authoritative_value_or_fallback(k)
      v = authoritative_value_or_fallback k
      case v
      when ::Hash
        ::Hash[(v.map { |k, vv| [ k.to_s.dup, vv.to_s.dup] })]
      when ::Array
        v.map { |vv| vv.to_s.dup }
      when ::String, ::Symbol
        v.to_s.dup
      else
        raise "i only handle arrays of strings, hashes of strings, and strings"
      end
    end
    
    # Used internally to pull a live list of emitters/datasets/etc. or fall back to a static one.
    def authoritative_value_or_fallback(k)
      k = k.to_s
      if (authority = authorities.detect { |a| a.authority? k })
        authority.send k
      else
        begin
          hsh = ::ActiveSupport::JSON.decode eat(LIVE_URL[k])
          kk = (k == 'certified_emitters') ? 'emitters' : k # the live certified response will contain an 'emitters' key
          raise unless hsh.has_key? kk
          hsh[kk]
        rescue
          FALLBACK[k]
        end
      end
    end
    cache_method :authoritative_value_or_fallback, 60
  end
end
