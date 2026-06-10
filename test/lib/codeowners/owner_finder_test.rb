# frozen_string_literal: true

require 'test_helper'
require 'codeowners/owner_finder'

module Codeowners
  class OwnerFinderTest < Minitest::Test
    test '#find_owners_for_file returns the names of the named owners when singular' do
      codeowners_file = Codeowners::CodeownersFile.new('foo @meetcleo/team-name')

      result = described_class.new(codeowners_file: codeowners_file).find_owners_for_file(filepath: 'foo')

      assert_includes result, 'team-name'
    end

    test '#find_owners_for_file returns the names of the named owners when multiple' do
      codeowners_file = Codeowners::CodeownersFile.new('foo @meetcleo/team-name @meetcleo/team-2-name')

      result = described_class.new(codeowners_file: codeowners_file).find_owners_for_file(filepath: 'foo')

      assert_includes result, 'team-name'
      assert_includes result, 'team-2-name'
    end

    test '#find_owners_for_file returns nil when file name not found' do
      codeowners_file = Codeowners::CodeownersFile.new('')

      result = described_class.new(codeowners_file: codeowners_file).find_owners_for_file(filepath: 'not-found')

      assert_empty result
    end
  end
end
