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
    include ::Singleton
    LIVE_URL = {
      'datasets'            => 'http://data.brighterplanet.com/datasets.json',
      'emitters'            => 'http://carbon.brighterplanet.com/emitters.json',
      'certified_emitters'  => 'http://certified.carbon.brighterplanet.com/emitters.json',
      'resources'           => 'http://data.brighterplanet.com/resources.json',
    }.freeze
    
    # sabshere 2/4/11 obv these have to be updated with some regularity
    FALLBACK = {
      'datasets'            => %w{ AutomobileIndustry FlightIndustry },
      'emitters'            => %w{ Automobile AutomobileTrip BusTrip Computation Diet Flight FuelPurchase Lodging Meeting Motorcycle Pet Purchase RailTrip Residence Shipment },
      'certified_emitters'  => %w{ },
      'resources'           => %w{ AirConditionerUse Aircraft AircraftClass AircraftManufacturer Airline Airport AutomobileFuelType AutomobileMake AutomobileMakeFleetYear AutomobileMakeModel AutomobileMakeModelYear AutomobileMakeModelYearVariant AutomobileMakeYear AutomobileSizeClass AutomobileSizeClassYear AutomobileTypeFuelAge AutomobileTypeFuelControl AutomobileTypeFuelYear AutomobileTypeFuelYearControl AutomobileTypeYear Breed BreedGender BusClass Carrier CarrierMode CensusDivision CensusRegion ClimateDivision ClothesMachineUse ComputationPlatform Country DataCenterCompany DietClass DishwasherUse EgridRegion EgridSubregion FlightDistanceClass FlightFuelType FlightSeatClass FlightSegment FoodGroup FuelPrice FuelType FuelYear Gender GreenhouseGas Industry IndustryProduct IndustryProductLine IndustrySector LodgingClass Merchant MerchantCategory MerchantCategoryIndustry PetroleumAdministrationForDefenseDistrict ProductLine ProductLineIndustryProduct RailClass ResidenceAppliance ResidenceClass ResidenceFuelPrice ResidenceFuelType ResidentialEnergyConsumptionSurveyResponse Sector ServerType ServerTypeAlias ShipmentMode Species State Urbanity ZipCode },
    }.freeze
    
    # What resources are available.
    def resources
      authoritative_list_or_fallback 'resources'
    end

    # What certified_emitters are available.
    def certified_emitters
      authoritative_list_or_fallback 'certified_emitters'
    end

    # What emitters are available.
    def emitters
      authoritative_list_or_fallback 'emitters'
    end

    # What datasets are available.
    def datasets
      authoritative_list_or_fallback 'datasets'
    end

    # Clear out any cached values
    def refresh
      instance_variables.each { |ivar_name| instance_variable_set ivar_name, nil }
    end
    
    private
    
    autoload :Cm1Adapter, 'brighter_planet_metadata/cm1_adapter'
    def cm1_adapter
      Cm1Adapter.instance
    end
    
    autoload :Data1Adapter, 'brighter_planet_metadata/data1_adapter'
    def data1_adapter
      Data1Adapter.instance
    end
    
    def adapters
      [ cm1_adapter, data1_adapter ]
    end
    
    # A universe of operation, for example an EngineYard AppCloud "environment"
    def universe
      @universe ||= if ::ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE'].present?
        ::ENV['BRIGHTER_PLANET_METADATA_FORCE_UNIVERSE']
      elsif ::File.readable? '/etc/brighterplanet/universe'
        ::File.read('/etc/brighterplanet/universe').chomp
      else
        'unknown'
      end
    end
    
    # Used internally to pull a live list of emitters/datasets/etc. or fall back to a static one.
    def authoritative_list_or_fallback(k)
      k = k.to_s
      ivar_name = :"@#{k}"
      if cached_v = instance_variable_get(ivar_name) and cached_v.is_a?(::Array)
        return cached_v.map(&:dup) # deep copy of an array with strings
      end
      v = if (adapter = adapters.detect { |a| a.authority? universe, k })
        adapter.send k
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
      raise "Unknown key #{k}" unless v.is_a? ::Array
      instance_variable_set ivar_name, v
      authoritative_list_or_fallback k
    end
  end
end
