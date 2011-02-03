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
    # sabshere 2/2/11 fallbacks current as of today
    URLS_AND_FALLBACKS = {
      'datasets'            => ['http://data.brighterplanet.com/datasets.json',             %w{ }],
      'beta_datasets'       => ['http://data.brighterplanet.com/datasets/beta.json',        %w{ AutomobileIndustry FlightIndustry }],
      'emitters'            => ['http://carbon.brighterplanet.com/emitters.json',           %w{ Automobile AutomobileTrip BusTrip Computation Diet Flight FuelPurchase Lodging Meeting Motorcycle Pet Purchase RailTrip Residence Shipment }],
      'beta_emitters'       => ['http://carbon.brighterplanet.com/emitters/beta.json',      %w{ }],
      'certified_emitters'  => ['http://certified.carbon.brighterplanet.com/emitters.json', %w{ }],
      # sabshere 2/2/11 lazy: Dir['lib/earth/**/*.rb'].select { |path| IO.read(path) =~ /class [A-Za-z]+ < ActiveRecord::Base/ }.map { |path| File.basename(path, '.rb') }.map(&:camelcase).sort.join(' ')
      'resources'           => ['http://data.brighterplanet.com/resources.json',            %w{ AirConditionerUse Aircraft AircraftClass AircraftManufacturer Airline Airport AutomobileFuelType AutomobileMake AutomobileMakeFleetYear AutomobileMakeModel AutomobileMakeModelYear AutomobileMakeModelYearVariant AutomobileMakeYear AutomobileSizeClass AutomobileSizeClassYear AutomobileTypeFuelAge AutomobileTypeFuelControl AutomobileTypeFuelYear AutomobileTypeFuelYearControl AutomobileTypeYear Breed BreedGender BusClass Carrier CarrierMode CensusDivision CensusRegion ClimateDivision ClothesMachineUse ComputationPlatform Country DataCenterCompany DietClass DishwasherUse EgridRegion EgridSubregion FlightDistanceClass FlightFuelType FlightSeatClass FlightSegment FoodGroup FuelPrice FuelType FuelYear Gender GreenhouseGas Industry IndustryProduct IndustryProductLine IndustrySector LodgingClass Merchant MerchantCategory MerchantCategoryIndustry PetroleumAdministrationForDefenseDistrict ProductLine ProductLineIndustryProduct RailClass ResidenceAppliance ResidenceClass ResidenceFuelPrice ResidenceFuelType ResidentialEnergyConsumptionSurveyResponse Sector ServerType ServerTypeAlias ShipmentMode Species State Urbanity ZipCode }],
      'beta_resources'      => ['http://data.brighterplanet.com/resources/beta.json',       %w{ }],
    }.freeze
    
    # What beta_resources are available.
    def beta_resources
      live_list_or_fallback 'beta_resources'
    end

    # What resources are available.
    def resources
      live_list_or_fallback 'resources'
    end

    # What certified_emitters are available.
    def certified_emitters
      live_list_or_fallback 'certified_emitters'
    end

    # What beta_emitters are available.
    def beta_emitters
      live_list_or_fallback 'beta_emitters'
    end

    # What emitters are available.
    def emitters
      live_list_or_fallback 'emitters'
    end

    # What datasets are available.
    def datasets
      live_list_or_fallback 'datasets'
    end

    # What beta_datasets are available.
    def beta_datasets
      live_list_or_fallback 'beta_datasets'
    end
        
    # Clear out any cached values
    def refresh
      instance_variables.each { |ivar_name| instance_variable_set ivar_name, nil }
    end
    
    private
    
    # A universe of operation, for example an EngineYard AppCloud "environment"
    def universe
      @universe ||= if ::File.readable? '/etc/brighterplanet/universe'
        ::File.read('/etc/brighterplanet/universe').chomp
      else
        'foreign'
      end
    end
    
    # Used internally to pull a live list of emitters/datasets/etc. or fall back to a static one.
    def live_list_or_fallback(k)
      k = k.to_s
      ivar_name = :"@#{k}"
      if cached_v = instance_variable_get(ivar_name) and cached_v.is_a?(::Array)
        return ::Marshal.load(::Marshal.dump(cached_v)) # deep copy!
      end
      v = begin
        live_list k
      rescue
        # $stderr.puts $!.inspect
        URLS_AND_FALLBACKS[k][1]
      end
      instance_variable_set ivar_name, v
      live_list_or_fallback k
    end
        
    class Cm1Adapter
      include ::Singleton
      def authority?(universe, method_id)
        return unless universe == 'cm1_production'
        method_id = method_id.to_s
        if method_id == 'certified_emitters'
          defined?(::Rails) and ::Rails.application.certified?
        else
          respond_to? method_id
        end
      end
      def emitters
        undifferentiated_emitters - beta_emitters
      end
      def beta_emitters
        undifferentiated_emitters.select do |name|
          begin
            "::BrighterPlanet::#{name}::BETA".constantize == true
          rescue ::NameError
            false
          end
        end
      end
      def certified_emitters
        emitters
      end
      private
      def undifferentiated_emitters
        ary = []
        ::ObjectSpace.each_object(::BrighterPlanet::Emitter) do |obj|
          ary.push obj.name.demodulize
        end
        ary
      end
    end
    
    class Data1Adapter
      include ::Singleton
      def authority?(universe, method_id)
        return unless universe == 'data1_production'
        respond_to? method_id
      end
      def resources
      end
      def beta_resources
      end
    end
    
    def cm1_adapter
      Cm1Adapter.instance
    end
    
    def data1_adapter
      Data1Adapter.instance
    end
    
    # Used internally to pull a live list, either from inside an application or from a URL
    def live_list(k)
      if cm1_adapter.authority?(universe, k)
        cm1_adapter.send k
      elsif data1_adapter.respond_to?(universe, k)
        data1_adapter.send k
      else
        ::ActiveSupport::JSON.decode eat(URLS_AND_FALLBACKS[k][0])
      end
    end
  end
end
