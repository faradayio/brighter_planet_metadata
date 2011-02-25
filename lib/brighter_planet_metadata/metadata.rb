require 'singleton'
require 'eat'
require 'active_support'
require 'active_support/version'
%w{
  active_support/json
  active_support/core_ext/object/blank
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3

module BrighterPlanet
  class Metadata
    autoload :AuthoritativeDnsResolver, 'brighter_planet_metadata/authoritative_dns_resolver'
    
    include ::Singleton
    LIVE_URL = {
      'datasets'            => 'http://data.brighterplanet.com/datasets.json',
      'emitters'            => 'http://carbon.brighterplanet.com/emitters.json',
      'certified_emitters'  => 'http://certified.carbon.brighterplanet.com/emitters.json',
      'resources'           => 'http://data.brighterplanet.com/resources.json',
      'protocols'           => 'http://carbon.brighterplanet.com/protocols.json',
      'color'               => 'http://carbon.brighterplanet.com/color.json'
    }.freeze
    
    # sabshere 2/4/11 obv these have to be updated with some regularity
    FALLBACK = {
      'datasets'            => %w{ AutomobileIndustry FlightIndustry },
      'emitters'            => %w{ Automobile AutomobileTrip BusTrip Computation Diet ElectricityUse Flight FuelPurchase Lodging Meeting Motorcycle Pet Purchase RailTrip Residence Shipment },
      'certified_emitters'  => %w{ },
      'resources'           => %w{ AirConditionerUse Aircraft AircraftClass AircraftManufacturer Airline Airport AutomobileFuelType AutomobileMake AutomobileMakeFleetYear AutomobileMakeModel AutomobileMakeModelYear AutomobileMakeModelYearVariant AutomobileMakeYear AutomobileSizeClass AutomobileSizeClassYear AutomobileTypeFuelAge AutomobileTypeFuelControl AutomobileTypeFuelYear AutomobileTypeFuelYearControl AutomobileTypeYear Breed BreedGender BusClass Carrier CarrierMode CensusDivision CensusRegion ClimateDivision ClothesMachineUse ComputationPlatform Country DataCenterCompany DietClass DishwasherUse EgridRegion EgridSubregion FlightDistanceClass FlightFuelType FlightSeatClass FlightSegment FoodGroup FuelPrice FuelType FuelYear Gender GreenhouseGas Industry IndustryProduct IndustryProductLine IndustrySector LodgingClass Merchant MerchantCategory MerchantCategoryIndustry PetroleumAdministrationForDefenseDistrict ProductLine ProductLineIndustryProduct RailClass ResidenceAppliance ResidenceClass ResidenceFuelPrice ResidenceFuelType ResidentialEnergyConsumptionSurveyResponse Sector ServerType ServerTypeAlias ShipmentMode Species State Urbanity ZipCode },
      'protocols'           => { 'ghg_protocol_scope_3' => 'Greenhouse Gas Protocol Scope 3', 'iso' => 'ISO 14064-1', 'tcr' => 'The Climate Registry', 'ghg_protocol_scope_1' => 'Greenhouse Gas Protocol Scope 1' },
      'color'               => 'unknown'
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
    
    # What 'color' the emission estimate service is today.
    def color
      deep_copy_of_authoritative_value_or_fallback 'color'
    end

    # Clear out any cached values
    def refresh
      # instance_variables.each { |ivar_name| instance_variable_set ivar_name, nil }
      clear_method_cache :authoritative_value_or_fallback
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
    
    # A universe of operation, for example an EngineYard AppCloud "environment"
    def universe
      if ::ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE'].present?
        ::ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE']
      elsif ::File.readable? '/etc/brighterplanet/universe'
        ::File.read('/etc/brighterplanet/universe').chomp
      else
        'unknown'
      end
    end
    
    def deep_copy_of_authoritative_value_or_fallback(k)
      v = authoritative_value_or_fallback k
      case v
      when ::Hash
        ::Hash[(v.map { |k, vv| [ k.dup, vv.dup] })]
      when ::Array
        v.map { |vv| vv.dup }
      when ::String
        v.dup
      end
    end
    
    # Used internally to pull a live list of emitters/datasets/etc. or fall back to a static one.
    def authoritative_value_or_fallback(k)
      k = k.to_s
      if (authority = authorities.detect { |a| a.authority? universe, k })
        authority.send k
      else
        begin
          hsh = ::ActiveSupport::JSON.decode eat(LIVE_URL[k])
          kk = (k == 'certified_emitters') ? 'emitters' : k # the certified response will contain an 'emitters' key
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
