# typed: false

# frozen_string_literal: true

require 'test_helper'
require 'codeowners/ownership'

module Codeowners
  class OwnershipTest < Minitest::Test
    test '#owner? returns true if any of the owners matches String' do
      glob_pattern = 'glob-pattern'
      owners = %w[team_a team_b]

      ownership = Codeowners::Ownership.new(glob_pattern, *owners)

      assert_equal true, ownership.owner?('team_a')
      assert_equal true, ownership.owner?('team_b')
      assert_equal false, ownership.owner?('team_c')
    end
  end
end
