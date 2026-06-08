# typed: false

# frozen_string_literal: true

module Codeowners
  # The Ownership class represents an codeowners rule from a GitHub CODEOWNERS file.
  # It includes methods to filter files matching the path expression and to check codeowners.
  class Ownership
    require 'forwardable'
    extend Forwardable

    require_relative 'glob'
    require_relative 'owner'

    # @return [Ownership::Glob] The path expression from the CODEOWNERS file
    attr_reader :glob

    # @return [Array<Codeowners::Owner>] The owners (team name) from the CODEOWNERS file
    attr_reader :owners

    # Initializes a new Ownership instance
    #
    # @param [String] glob The file path pattern from the CODEOWNERS file
    # @param [Array<String>] owners The owners (team names) associated with the path expression
    def initialize(glob, *owners)
      @glob = Glob.new(glob)
      @owners = owners.map { |owner| Owner.new(owner) }
    end

    # Checks if a given owner name matches the owner of this path expression
    #
    # @param owner_name [String] the owner name to check
    # @return [Boolean] true if the given owner name matches, false otherwise
    def owner?(owner_name)
      owners.any? { |owner| owner.match?(owner_name) }
    end

    def_delegator :glob, :match?, :glob_match?
  end
end
