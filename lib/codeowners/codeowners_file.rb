# typed: false

# frozen_string_literal: true

module Codeowners
  # Parses a Codeowners file
  class CodeownersFile
    require 'forwardable'
    require_relative 'glob'
    require_relative 'ownership'

    extend Forwardable

    attr_reader :source
    private :source

    def_delegators :source, :lines, :to_s

    # @param [String] codeowners_source A String containing the readlines from the CODEOWNERS file
    def initialize(codeowners_source = File.read('./.github/CODEOWNERS'))
      @source = codeowners_source
    end

    def ownerships_reversed
      @ownerships_reversed ||= ownerships.reverse
    end

    def ownerships
      @ownerships ||= lines.map { |line| Ownership.new(*line.to_s.split) }
    end

    def globs
      @globs ||= lines.map { |line| Glob.new(line.to_s.split.first) }
    end
  end
end
