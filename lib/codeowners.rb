# typed: false
# frozen_string_literal: true

module Codeowners
  require_relative 'codeowners/owner'
  require_relative 'codeowners/glob'
  require_relative 'codeowners/ownership'
  require_relative 'codeowners/codeowners_file'
  require_relative 'codeowners/owner_finder'
  require_relative 'codeowners/definitions_file'
  require_relative 'codeowners/contributor_finder'
  require_relative 'codeowners/generator'
end
