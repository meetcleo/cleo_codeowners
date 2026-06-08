# typed: false
# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'
require 'pathname'
require 'yaml'

module Codeowners
  # Parses Cleo Codeowners YAML files
  class DefinitionsFile
    # @param [String] definition_glob String containing the glob pattern for the Cleo codeowner YAML files
    def initialize(definition_glob = '.cleo/codeowners/**/*.y*ml')
      @definition = Dir[definition_glob].inject({}) do |yaml, filepath|
        yaml.deep_merge(YAML.load_file(filepath))
      end
    end

    attr_reader :definition

    def features_config
      definition['features'] || {}
    end

    def owners_config
      definition['owners'] || {}
    end

    def file_config
      definition['files'] || {}
    end

    # Finds files defined under a feature, expands all globs, and returns all of them
    # @return [Array,<Pathname>]
    def feature_paths(feature:, directory: nil)
      relative_globs = Array(file_config[feature]).map { |path| "./#{path}" }
      resolve_local_paths(relative_globs:, directory: directory || Pathname.pwd)
    end

    # Finds a feature the file belongs to
    # @return [nil, String]
    def find_feature_for_file(path:)
      return nil unless path

      target_path = File.join('.', path)
      file_config.each do |feature, paths|
        next unless paths

        paths.each do |feature_path|
          path_pattern = File.join('.', feature_path)
          path_pattern = "#{path_pattern}/*" if path_pattern.end_with?('/')
          path_pattern.gsub!('//', '/')

          return feature if File.fnmatch(path_pattern, target_path)
        end
      end

      nil
    end

    Match = Data.define(:feature, :path_pattern)

    # Finds a feature the file belongs to
    # @return Array
    def find_features_for_file(path:)
      return [] unless path

      target_path = File.join('.', path)
      file_config.filter_map do |feature, paths|
        next unless paths

        paths.filter_map do |feature_path|
          path_pattern = File.join('.', feature_path)
          path_pattern = "#{path_pattern}/*" if path_pattern.end_with?('/')
          path_pattern.gsub!('//', '/')

          Match.new(feature, path_pattern) if File.fnmatch(path_pattern, target_path)
        end
      end.flatten.uniq
    end

    private

    def resolve_local_paths(directory:, relative_globs:)
      directory
        .glob(relative_globs)
        .flat_map { |pathname| pathname.directory? ? pathname.glob('**/*') : pathname }
        .map { |pathname| pathname.relative_path_from(directory) }
    end
  end
end
