# typed: false
# frozen_string_literal: true

require 'test_helper'
require 'codeowners/definitions_file'

module Codeowners
  class DefinitionsFileTest < Minitest::Test
    def setup
      @test_directory = Pathname.new(__dir__)
    end

    def definitions_file
      DefinitionsFile.new(@test_directory.join('fixtures/**/*.yaml').to_path)
    end

    test 'gracefully handles bad locations' do
      file = DefinitionsFile.new('./does-not-exist/really/*')

      assert_empty file.definition
      assert_empty file.file_config
      assert_empty file.owners_config
      assert_empty file.features_config
    end

    test 'merges all YAML files into the definition' do
      expected_teams = ['chat', 'chat evaluations']

      assert_equal expected_teams, definitions_file.file_config.keys
      assert_equal expected_teams, definitions_file.owners_config.keys
      assert_equal expected_teams, definitions_file.features_config.keys
    end

    test '#feature_paths returns all files defined under a feature, relative to given directory' do
      assert_equal [Pathname.new('definitions_file_test.rb'), Pathname.new('fixtures/files/test-chat_evaluations.yaml')],
                   definitions_file.feature_paths(feature: 'chat evaluations', directory: @test_directory)

      assert_equal [Pathname.new('fixtures/files/test-chat.yaml'), Pathname.new('fixtures/files/test-chat_evaluations.yaml')],
                   definitions_file.feature_paths(feature: 'chat', directory: @test_directory)
    end

    test '#feature_paths handles missing features gracefully, returning nothing' do
      files = definitions_file.feature_paths(feature: 'smaug_dragon_hoard', directory: @test_directory)

      assert_empty files
    end

    test '#find_feature*_for_file finds the feature for the given filepath' do
      assert_nil definitions_file.find_feature_for_file(path: nil)
      assert_nil definitions_file.find_feature_for_file(path: 'nonexistent')

      assert_equal 'chat evaluations', definitions_file.find_feature_for_file(path: 'definitions_file.rb'),
                   'matches glob in files.yaml'
      assert_equal 'chat evaluations', definitions_file.find_feature_for_file(path: 'definitions_file_test.rb'),
                   'matches glob in files.yaml'

      assert_empty definitions_file.find_features_for_file(path: nil)
      assert_empty definitions_file.find_features_for_file(path: 'nonexistent')

      assert_equal [described_class::Match.new('chat evaluations', './definitions_file*.rb')],
                   definitions_file.find_features_for_file(path: 'definitions_file.rb'), 'matches glob in files.yaml'

      assert_equal [described_class::Match.new('chat evaluations', './definitions_file*.rb')],
                   definitions_file.find_features_for_file(path: 'definitions_file_test.rb'), 'matches glob in files.yaml'
    end

    test '#find_feature*_for_file finds files defined under directories' do
      assert_equal 'chat', definitions_file.find_feature_for_file(path: 'fixtures/files/nested/folder/file'),
                   'matches nested folders'
      assert_equal 'chat', definitions_file.find_feature_for_file(path: 'fixtures/files/test-chat_evaluations.yaml'),
                   'matches full file'
      assert_equal 'chat', definitions_file.find_feature_for_file(path: 'fixtures/files/test'), 'matches partial file'

      assert_equal [described_class::Match.new('chat', './fixtures/files/*')],
                   definitions_file.find_features_for_file(path: 'fixtures/files/nested/folder/file'), 'matches nested folders'

      assert_equal(
        [
          described_class::Match.new('chat', './fixtures/files/*'),
          described_class::Match.new('chat evaluations', './fixtures/files/*eval*')
        ],
        definitions_file.find_features_for_file(path: 'fixtures/files/test-chat_evaluations.yaml'),
        'matches full file'
      )

      assert_equal [described_class::Match.new('chat', './fixtures/files/*')],
                   definitions_file.find_features_for_file(path: 'fixtures/files/test'), 'matches partial file'
    end
  end
end
