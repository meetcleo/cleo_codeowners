# typed: false

# frozen_string_literal: true

module Codeowners
  require 'delegate'

  class Glob
    require 'forwardable'
    extend Forwardable

    # The glob pattern this glob will match
    #
    # @return [String]
    # @see #match?
    attr_reader :pattern

    def_delegator :File, :fnmatch, :fnmatch
    def_delegator :pattern, :to_s

    def initialize(string)
      @pattern = normalize_string(string)
    end

    # Does this glob match the given filepath?
    # @param [String] filepath to match against
    # @note
    #   Don't use `FNM_CASEFOLD`, GitHub uses a case sensitive file system.
    #   Don't use `FNM_EXTGLOB`, GitHub CODEOWNERS files don't support it.
    #   Don't use `FNM_PATHNAME`, we want to match `*` against '/'.
    #
    # @see https://docs.ruby-lang.org/en/3.3/File.html#method-c-fnmatch
    # @return [Boolean]
    def match?(filepath)
      fnmatch(pattern, filepath, File::FNM_DOTMATCH)
    end

    private

    def normalize_string(string)
      string.to_s.delete_prefix('/') # remove leading slashes
        .gsub(%r{/\Z}, '/**') # replace trailing slash with a recursive wildcard
    end
  end
end
