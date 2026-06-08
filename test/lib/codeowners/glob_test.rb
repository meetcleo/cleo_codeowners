# typed: false

# frozen_string_literal: true

require 'test_helper'
require 'codeowners/glob'

module Codeowners
  class GlobTest < Minitest::Test
    test '#initialize normalizes pattern by removing leading slashes and replacing trailing slashes' do
      pattern = '/some/pattern/'
      expected_pattern = 'some/pattern/**'

      glob = Codeowners::Glob.new(pattern)

      assert_equal expected_pattern, glob.pattern
    end

    test '#match? returns true for matching filepath' do
      pattern = 'lib/*.rb'
      filepath = 'lib/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?(filepath)
    end

    test '#match? returns true for recursive directory matching' do
      pattern = 'lib/'
      filepath = 'lib/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?(filepath)
    end

    test '#match? returns false for non-matching filepath' do
      pattern = 'lib/**/*.rb'
      filepath = 'app/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal false, glob.match?(filepath)
    end
  end
end
