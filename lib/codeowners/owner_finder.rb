# typed: false
# frozen_string_literal: true

module Codeowners
  class OwnerFinder
    attr_reader :codeowners_file
    private :codeowners_file

    def self.singleton(...)
      @singleton ||= new(...)
    end

    def initialize(codeowners_file:)
      @codeowners_file = codeowners_file
    end

    # Find the most likely owners of the file with the given filepath. Returns the owner name as an Array of Strings
    # (e.g. ["card-1-be", "card-2-be"])
    # @return [Array,<String>]
    def find_owners_for_file(filepath:)
      last_matching_ownership = find_ownership_for_file(filepath:)
      return [] if last_matching_ownership.nil?

      last_matching_ownership.owners.map(&:to_s)
    end

    # Find the most likely owners of the file with the given filepath. Returns
    # @return [Ownership]
    def find_ownership_for_file(filepath:)
      codeowners_file.ownerships_reversed.find do |ownership|
        ownership.glob_match?(filepath)
      end
    end
  end
end
