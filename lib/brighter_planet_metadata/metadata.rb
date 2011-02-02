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
      live_value_or_fallback 'beta_resources'
    end

    # What resources are available.
    def resources
      live_value_or_fallback 'resources'
    end

    # What certified_emitters are available.
    def certified_emitters
      live_value_or_fallback 'certified_emitters'
    end

    # What beta_emitters are available.
    def beta_emitters
      live_value_or_fallback 'beta_emitters'
    end

    # What emitters are available.
    def emitters
      live_value_or_fallback 'emitters'
    end

    # What datasets are available.
    def datasets
      live_value_or_fallback 'datasets'
    end

    # What beta_datasets are available.
    def beta_datasets
      live_value_or_fallback 'beta_datasets'
    end
    
    # Clear out any cached values
    def refresh
      instance_variables.each { |ivar_name| instance_variable_set ivar_name, nil }
    end
    
    private
    
    def live_value_or_fallback(name)
      name = name.to_s
      ivar_name = :"@#{name}"
      if cached_value = instance_variable_get(ivar_name) and cached_value.is_a?(::Array)
        return cached_value.dup
      end
      value = begin
        ::ActiveSupport::JSON.decode eat(URLS_AND_FALLBACKS[name][0])
      rescue
        URLS_AND_FALLBACKS[name][1]
      end
      instance_variable_set ivar_name, value
      live_value_or_fallback name
    end
  end
end
