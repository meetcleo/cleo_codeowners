# frozen_string_literal: true

module Codeowners
  # Stores configuration options for the Codeowners gem.
  class Configuration
    ##
    # Organization/team name strings should begin with an @ symbol
    AT_PREFIX = '@'
    private_constant :AT_PREFIX

    ##
    # Raised when a required configuration value is missing
    class MissingConfigurationError < Error; end

    def self.instance
      @instance ||= new
    end

    def self.reset_singleton_instance!
      @instance = nil
    end

    ##
    # @param [String] organization_name the name of the Github organization
    def initialize(organization_name: nil)
      self.organization_name = organization_name
    end

    ##
    # The organization name for teams
    # @return [String] the name of the organization
    def organization_name
      raise MissingConfigurationError, "Organization name is required" if @organization_name.nil?

      @organization_name.dup
    end

    ##
    # Set the default organization name for teams
    # @param [String] value the name of the organization
    def organization_name=(value)
      value = value.to_s.dup
      value.prepend(AT_PREFIX) unless value.start_with?(AT_PREFIX)
      @organization_name = value
    end
  end
end
