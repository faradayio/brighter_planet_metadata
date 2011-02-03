require 'singleton'
require 'eat'
require 'active_support'
require 'active_support/version'
%w{
  active_support/json
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3

module BrighterPlanet
  class Metadata
    include ::Singleton
    LIVE_URL = {
      'datasets'            => 'http://data.brighterplanet.com/datasets.json',
      'beta_datasets'       => 'http://data.brighterplanet.com/datasets/beta.json',
      'emitters'            => 'http://carbon.brighterplanet.com/emitters.json',
      'beta_emitters'       => 'http://carbon.brighterplanet.com/emitters/beta.json',
      'certified_emitters'  => 'http://certified.carbon.brighterplanet.com/emitters.json',
      'resources'           => 'http://data.brighterplanet.com/resources.json',
      'beta_resources'      => 'http://data.brighterplanet.com/resources/beta.json',
    }.freeze
    
    # sabshere 2/2/11 fallbacks current as of today
    FALLBACK = {
      'datasets'            => %w{ },
      'beta_datasets'       => %w{ AutomobileIndustry FlightIndustry },
      'emitters'            => %w{ Automobile AutomobileTrip BusTrip Computation Diet Flight FuelPurchase Lodging Meeting Motorcycle Pet Purchase RailTrip Residence Shipment },
      'beta_emitters'       => %w{ },
      'certified_emitters'  => %w{ },
      'resources'           => %w{ AirConditionerUse Aircraft AircraftClass AircraftManufacturer Airline Airport AutomobileFuelType AutomobileMake AutomobileMakeFleetYear AutomobileMakeModel AutomobileMakeModelYear AutomobileMakeModelYearVariant AutomobileMakeYear AutomobileSizeClass AutomobileSizeClassYear AutomobileTypeFuelAge AutomobileTypeFuelControl AutomobileTypeFuelYear AutomobileTypeFuelYearControl AutomobileTypeYear Breed BreedGender BusClass Carrier CarrierMode CensusDivision CensusRegion ClimateDivision ClothesMachineUse ComputationPlatform Country DataCenterCompany DietClass DishwasherUse EgridRegion EgridSubregion FlightDistanceClass FlightFuelType FlightSeatClass FlightSegment FoodGroup FuelPrice FuelType FuelYear Gender GreenhouseGas Industry IndustryProduct IndustryProductLine IndustrySector LodgingClass Merchant MerchantCategory MerchantCategoryIndustry PetroleumAdministrationForDefenseDistrict ProductLine ProductLineIndustryProduct RailClass ResidenceAppliance ResidenceClass ResidenceFuelPrice ResidenceFuelType ResidentialEnergyConsumptionSurveyResponse Sector ServerType ServerTypeAlias ShipmentMode Species State Urbanity ZipCode },
      'beta_resources'      => %w{ },
    }.freeze
    
    # What beta_resources are available.
    def beta_resources
      authoritative_list_or_fallback 'beta_resources'
    end

    # What resources are available.
    def resources
      authoritative_list_or_fallback 'resources'
    end

    # What certified_emitters are available.
    def certified_emitters
      authoritative_list_or_fallback 'certified_emitters'
    end

    # What beta_emitters are available.
    def beta_emitters
      authoritative_list_or_fallback 'beta_emitters'
    end

    # What emitters are available.
    def emitters
      authoritative_list_or_fallback 'emitters'
    end

    # What datasets are available.
    def datasets
      authoritative_list_or_fallback 'datasets'
    end

    # What beta_datasets are available.
    def beta_datasets
      authoritative_list_or_fallback 'beta_datasets'
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
      @universe ||= if ::File.readable? '/etc/brighterplanet/universe'
        ::File.read('/etc/brighterplanet/universe').chomp
      else
        'foreign'
      end
    end
    
    # Used internally to pull a live list of emitters/datasets/etc. or fall back to a static one.
    def authoritative_list_or_fallback(k)
      k = k.to_s
      ivar_name = :"@#{k}"
      if cached_v = instance_variable_get(ivar_name) and cached_v.is_a?(::Array)
        return ::Marshal.load(::Marshal.dump(cached_v)) # deep copy!
      end
      v = authoritative_list(k) || FALLBACK[k]
      instance_variable_set ivar_name, v
      authoritative_list_or_fallback k
    end
    
    # Used internally to pull a live list, either from inside an application or from a URL
    def authoritative_list(k)
      if adapter = adapters.detect { |a| a.authority? universe, k }
        adapter.send k
      else
        begin
          ::ActiveSupport::JSON.decode eat(LIVE_URL[k])
        rescue ::SocketError, ::EOFError, ::Timeout::Error, ::Errno::ETIMEDOUT, ::Errno::ENETUNREACH, ::Errno::ECONNRESET, ::Errno::ECONNREFUSED
          # just return nil so that a fallback is used
        end
      end
    end
  end
end
