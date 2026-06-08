# typed: false

# frozen_string_literal: true

module Codeowners
  class Owner
    # Prefix for team names in the CODEOWNERS file
    # @return [String]
    TEAM_NAME_PREFIX = '@meetcleo/'

    # Name of team in CODEOWNERS file (e.g. @meetcleo/card-1-be)
    # @return [String]
    attr_reader :name

    # @param [String] name_string Name of team in CODEOWNERS file (e.g. `"@meetcleo/card-1-be"`)
    def initialize(name_string)
      name_string = "#{TEAM_NAME_PREFIX}#{name_string}" unless name_string.start_with?(TEAM_NAME_PREFIX)
      @name = name_string
    end

    # Does this string match the name of the owner?
    # @return [Boolean]
    def match?(compare_string)
      compare_string = "#{TEAM_NAME_PREFIX}#{compare_string}" unless compare_string.start_with?(TEAM_NAME_PREFIX)
      name == compare_string.to_s.downcase
    end

    def to_s
      name.gsub(TEAM_NAME_PREFIX, '')
    end
  end
end
