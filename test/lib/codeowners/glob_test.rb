# typed: false

# frozen_string_literal: true

require 'test_helper'
require 'codeowners/glob'

module Codeowners
  class GlobTest < Minitest::Test
    test '#initialize normalizes pattern by removing leading slashes and replacing trailing slashes' do
      pattern = '/some/pattern/'
      expected_pattern = 'some/pattern/**/*'

      glob = Codeowners::Glob.new(pattern)

      assert_equal expected_pattern, glob.pattern
    end

    test '#match? returns true for identical filepath' do
      pattern = 'lib/test_file.rb'
      filepath = 'lib/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?(filepath)
    end

    test '#match? returns true for identical filepath with trailing /' do
      pattern = 'lib/'
      filepath = 'lib/'

      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?(filepath)
    end

    test '#match? returns true for matching filepath' do
      pattern = 'lib/*.rb'
      filepath = 'lib/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?(filepath)
    end

    test '#match? returns false for deeper filepaths with *' do
      pattern = 'lib/*.rb'
      filepath = 'lib/folder/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal false, glob.match?(filepath)
    end

    test '#match? returns true for recursive directory matching' do
      pattern = 'lib/'
      filepath = 'lib/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?(filepath)
    end

    test '#match? returns true for any depth of recursive directory matching' do
      pattern = 'lib/'
      filepath = 'lib/foo/bar/baz/bam/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?(filepath)
    end

    test '#match? matches a leading ** that is 0 folders deep' do
      pattern = '/**/test_folder/'
      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?('test_folder/test_file.rb')
    end

    test '#match? matches a leading ** that is many folders deep' do
      pattern = '/**/test_folder/'
      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?('lib/foo/bar/baz/bam/test_folder/test_file.rb')
    end

    test '#match? matches an embedded ** across zero folders' do
      pattern = 'lib/**/*.rb'
      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?('lib/foo.rb')
      assert_equal true, glob.match?('lib/foo/bar/baz/bam/foo.rb')
    end

    test '#match? matches an embedded ** across multiple folders' do
      pattern = 'lib/**/*.rb'
      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?('lib/foo/bar/baz/bam/foo.rb')
    end

    test '#match? treats ? as a single non-slash character' do
      pattern = '/lib/foo?.rb'
      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?('lib/foo1.rb')
      assert_equal false, glob.match?('lib/foo.rb')
    end

    test '#match? does not match for a trailing ** without a / with subsequent directories' do
      pattern = '/lib/foo**'
      glob = Codeowners::Glob.new(pattern)

      assert_equal true, glob.match?('lib/foo.rb')
      assert_equal false, glob.match?('lib/foo/test_file.rb')
    end

    test '#match? returns false for non-matching filepath' do
      pattern = 'lib/**/*.rb'
      filepath = 'app/test_file.rb'

      glob = Codeowners::Glob.new(pattern)

      assert_equal false, glob.match?(filepath)
    end
  end
end
