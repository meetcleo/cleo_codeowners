# typed: false

# frozen_string_literal: true

module Codeowners
  class Owner

    ##
    # Name of team in CODEOWNERS file (e.g. @meetcleo/chat)
    # @return [String]
    attr_reader :name
    alias long_name name

    ##
    # Name of team in config files (e.g. chat)
    # @return [String]
    attr_reader :short_name

    # @param [String] name_string Name of team in CODEOWNERS file (e.g. `"@meetcleo/chat"`)
    def initialize(name_string)
      name_string = "#{organization_name}/#{name_string}" unless name_string.start_with?(organization_name)
      @name = name_string
      @short_name = name_string.split("/").last
    end

    # Prefix for team names in the CODEOWNERS file
    # @return [String]
    def organization_name = Configuration.instance.organization_name

    # Does this string match the name of the owner?
    # @return [Boolean]
    def match?(compare_string)
      compare_string = "#{organization_name}/#{compare_string}" unless compare_string.start_with?(organization_name)
      name == compare_string.to_s.downcase
    end

    def to_s
      name.gsub(organization_name, '')
    end
  end
end
