# typed: false
# frozen_string_literal: true

require 'test_helper'
require 'codeowners/contributor_finder'
require 'codeowners/definitions_file'

module Codeowners
  class ContributorFinderTest < Minitest::Test
    test 'returns empty array when no files found for feature' do
      definitions_file = DefinitionsFile.new
      contributor_finder = ContributorFinder.new(definitions_file:)

      result = contributor_finder.find_contributors(feature: 'nonexistent_feature_xyz')

      assert_empty result
    end

    test 'finds contributors and parses git log output correctly' do
      definitions_file = definitions_file_with_paths('lib/codeowners.rb', 'bin/cleo-codeowners')
      contributor_finder = ContributorFinder.new(definitions_file:, max_commits: 5)

      # Mock git log to return sample data
      git_output = <<~GIT
        abc123|alice@example.com|2026-03-01

        10\t5\tlib/codeowners.rb
        20\t3\tbin/cleo-codeowners

        def456|bob@example.com|2026-03-02

        5\t2\tlib/codeowners.rb
      GIT

      success_status = stub('ProcessStatus', success?: true)
      Open3.expects(:capture2).with do |*args|
        args[0] == 'git' && args[1] == 'log' && args.include?('--numstat')
      end.returns([git_output, success_status])

      # Mock gh API calls to return usernames
      gh_alice_result = stub('ProcessStatus', success?: true)
      Open3.expects(:capture2).with do |*args|
        args[0] == 'gh' && args[1] == 'api' && args[2].include?('alice@example.com')
      end.returns(["alice_gh\n", gh_alice_result])

      gh_bob_result = stub('ProcessStatus', success?: true)
      Open3.expects(:capture2).with do |*args|
        args[0] == 'gh' && args[1] == 'api' && args[2].include?('bob@example.com')
      end.returns(["bob_gh\n", gh_bob_result])

      result = contributor_finder.find_contributors(feature: 'codeowners backend')

      assert_equal 2, result.length
      assert_equal 'alice_gh', result[0].username
      assert_equal 38, result[0].lines_changed
      assert_equal 30, result[0].additions
      assert_equal 8, result[0].deletions
      assert_equal 1, result[0].commits
      assert_equal '2026-03-01', result[0].first_commit_date
      assert_equal '2026-03-01', result[0].last_commit_date

      assert_equal 'bob_gh', result[1].username
      assert_equal 7, result[1].lines_changed
      assert_equal 1, result[1].commits
    end

    test 'sorts contributors by lines changed descending' do
      definitions_file = definitions_file_with_paths('test.rb')
      contributor_finder = ContributorFinder.new(definitions_file:, max_commits: 10)

      git_output = <<~GIT
        abc123|user1@example.com|2026-03-01

        10\t5\ttest.rb

        def456|user2@example.com|2026-03-02

        100\t50\ttest.rb

        ghi789|user3@example.com|2026-03-03

        20\t10\ttest.rb
      GIT

      success_status = stub('ProcessStatus', success?: true)
      Open3.expects(:capture2).with do |*args|
        args[0] == 'git' && args[1] == 'log'
      end.returns([git_output, success_status])

      # Mock gh API calls
      [['user1@example.com', 'user1'], ['user2@example.com', 'user2'], ['user3@example.com', 'user3']].each do |email, username|
        gh_result = stub('ProcessStatus', success?: true)
        Open3.expects(:capture2).with do |*args|
          args[0] == 'gh' && args[1] == 'api' && args[2].include?(email)
        end.returns(["#{username}\n", gh_result])
      end

      result = contributor_finder.find_contributors(feature: 'codeowners backend')

      assert_equal 3, result.length
      assert_equal 'user2', result[0].username
      assert_equal 150, result[0].lines_changed
      assert_equal 1, result[0].commits
      assert_equal 'user3', result[1].username
      assert_equal 30, result[1].lines_changed
      assert_equal 1, result[1].commits
      assert_equal 'user1', result[2].username
      assert_equal 15, result[2].lines_changed
      assert_equal 1, result[2].commits
    end

    test 'handles gh API failure gracefully by using email prefix' do
      definitions_file = definitions_file_with_paths('test.rb')
      contributor_finder = ContributorFinder.new(definitions_file:, max_commits: 5)

      git_output = <<~GIT
        abc123|unknown@example.com|2026-03-01

        10\t5\ttest.rb
      GIT

      success_status = stub('ProcessStatus', success?: true)
      Open3.expects(:capture2).with do |*args|
        args[0] == 'git' && args[1] == 'log'
      end.returns([git_output, success_status])

      # Mock gh API to fail
      fail_status = stub('ProcessStatus', success?: false)
      Open3.expects(:capture2).with do |*args|
        args[0] == 'gh' && args[1] == 'api'
      end.returns(['', fail_status])

      result = contributor_finder.find_contributors(feature: 'codeowners backend')

      assert_equal 1, result.length
      assert_equal 'unknown', result[0].username
    end

    test 'collects files from nested subfeatures recursively' do
      definitions_file = stub('DefinitionsFile')
      # In the actual features.yaml structure, all features are top-level keys
      # The nesting represents parent-child relationships
      definitions_file.stubs(:features_config).returns({
                                                         'parent' => {
                                                           'child1' => {},
                                                           'child2' => {},
                                                         },
                                                         'child1' => {
                                                           'grandchild1' => nil,
                                                           'grandchild2' => nil,
                                                         },
                                                         'child2' => nil,
                                                         'grandchild1' => nil,
                                                         'grandchild2' => nil,
                                                       })
      definitions_file.stubs(:feature_paths).with(feature: 'parent').returns([Pathname.new('parent.rb')])
      definitions_file.stubs(:feature_paths).with(feature: 'child1').returns([Pathname.new('child1.rb')])
      definitions_file.stubs(:feature_paths).with(feature: 'child2').returns([Pathname.new('child2.rb')])
      definitions_file.stubs(:feature_paths).with(feature: 'grandchild1').returns([Pathname.new('grandchild1.rb')])
      definitions_file.stubs(:feature_paths).with(feature: 'grandchild2').returns([Pathname.new('grandchild2.rb')])

      contributor_finder = ContributorFinder.new(definitions_file:, max_commits: 5)

      git_output = <<~GIT
        abc123|user@example.com|2026-03-01

        10\t5\tparent.rb
      GIT

      success_status = stub('ProcessStatus', success?: true)
      Open3.expects(:capture2).with do |*args|
        # Verify all the right arguments are present, regardless of file order
        args[0] == 'git' && args[1] == 'log' &&
          args.include?('--numstat') && args.include?('--date=short') &&
          args.include?('--') &&
          args.include?('parent.rb') && args.include?('child1.rb') &&
          args.include?('child2.rb') && args.include?('grandchild1.rb') &&
          args.include?('grandchild2.rb')
      end.returns([git_output, success_status])

      gh_result = stub('ProcessStatus', success?: true)
      Open3.expects(:capture2).with do |*args|
        args[0] == 'gh' && args[1] == 'api'
      end.returns(["user\n", gh_result])

      result = contributor_finder.find_contributors(feature: 'parent')

      assert_equal 1, result.length
      assert_equal 'user', result[0].username
    end

    private

    def definitions_file_with_paths(*paths)
      definitions_file = stub('DefinitionsFile')
      definitions_file.stubs(:feature_paths).with(feature: 'codeowners backend').returns(paths.map { |path| Pathname.new(path) })
      definitions_file.stubs(:features_config).returns({})
      definitions_file
    end
  end
end
