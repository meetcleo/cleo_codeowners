# typed: false

# frozen_string_literal: true

require 'test_helper'
require 'codeowners/owner'

module Codeowners
  class OwnerTest < Minitest::Test
    test '#initialize prefixes name if not already prefixed' do
      name_string = 'team-name'
      expected_name = '@meetcleo/team-name'

      owner = Codeowners::Owner.new(name_string)

      assert_equal expected_name, owner.name
    end

    test '#initialize does not prefix name if already prefixed' do
      name_string = '@meetcleo/team-name'
      expected_name = '@meetcleo/team-name'

      owner = Codeowners::Owner.new(name_string)

      assert_equal expected_name, owner.name
    end

    test '#match? returns true for matching name without prefix' do
      name_string = 'team-name'
      owner = Codeowners::Owner.new(name_string)

      assert_equal true, owner.match?('team-name')
    end

    test '#match? returns true for matching name with prefix' do
      name_string = '@meetcleo/team-name'
      owner = Codeowners::Owner.new(name_string)

      assert_equal true, owner.match?('@meetcleo/team-name')
    end

    test '#match? returns false for non-matching name' do
      name_string = 'team-name'
      owner = Codeowners::Owner.new(name_string)

      assert_equal false, owner.match?('other-team')
    end
  end
end
