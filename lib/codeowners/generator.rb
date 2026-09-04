# typed: false
# frozen_string_literal: true

require 'pathname'

module Codeowners
  class Generator
    DEFAULT_OUTPUT_PATH = '.github/CODEOWNERS'
    DEFAULT_HUMAN_OUTPUT_PATH = '.github/CODEOWNERS-HUMAN'

    def initialize(
      definitions_file: DefinitionsFile.new,
      output_path: DEFAULT_OUTPUT_PATH,
      human_output_path: DEFAULT_HUMAN_OUTPUT_PATH
    )
      @definitions_file = definitions_file
      @output_path = output_path
      @human_output_path = human_output_path
      @calculated_owners = []
      @all_features = []
    end

    def call
      File.open(output_path, 'w') do |output_file|
        File.open(human_output_path, 'w') do |output_human_file|
          @output_file = output_file
          @output_human_file = output_human_file

          output(blurb, depth: 0)
          calculate_owners_and_output_in_human_format(features: top_level_features)
          validate_owners_in_features
          output_in_machine_format
        end
      end
    ensure
      @output_file = nil
      @output_human_file = nil
    end

    private

    attr_reader :all_features,
                :calculated_owners,
                :definitions_file,
                :human_output_path,
                :output_file,
                :output_human_file,
                :output_path

    def owners
      @owners ||= definitions_file.owners_config
    end

    def top_level_features
      @top_level_features ||= definitions_file.features_config
    end

    def files
      @files ||= definitions_file.file_config
    end

    def calculate_owners_and_output_in_human_format(features:, current_owner: nil, depth: 0)
      return unless present?(features)

      features.sort_by(&:first).each do |feature, children|
        output(feature.upcase, depth:)
        owner = owners.fetch(feature, current_owner)
        feature_files = files[feature]

        if blank?(owner)
          raise "Please assign an owner for #{feature} in owners.yaml!"
        elsif blank?(feature_files) && blank?(children)
          raise "Please assign files or child features to #{feature}, or remove it!"
        else
          all_features << feature
        end

        if owner == 'unowned'
          output('Currently unowned', depth:)
        else
          output("Currently owned by @meetcleo/#{owner}", depth:)
        end

        if present?(feature_files)
          feature_files.sort.uniq.each do |file|
            record_calculated_owner(file, Owner.new(owner).long_name)
            output("#{file} #{Owner.new(owner).long_name}", depth:, comment: false)
          end
        end

        calculate_owners_and_output_in_human_format(features: children, current_owner: owner, depth: depth + 1)
      end
    end

    def output(string, depth:, comment: true)
      string.split("\n").each do |line|
        line = if comment
                 "#{' ' * (depth * 2)}# #{line}"
               else
                 "#{' ' * ((depth + 1) * 2)}#{line}"
               end
        output_human_file << line.rstrip << "\n"
      end
    end

    def record_calculated_owner(path, owner)
      calculated_owners.push({ path:, owner: })
    end

    # GitHub applies the *last* matching CODEOWNERS rule, so rules are listed
    # least-specific first: by number of path segments (`/app/` is broader than
    # `/app/models/user.rb`), then by path so a wildcard such as `/foo/*` sorts
    # ahead of the `/foo/bar/` it would otherwise shadow.
    def output_in_machine_format
      merge_owners_by_path(calculated_owners)
        .sort_by { |path, _owners| [path_depth(path), path] }
        .each { |path, rule_owners| output_file << "#{path} #{rule_owners.join(' ')}\n" }
    end

    # Combines the owners of rules that share a path onto one line.
    def merge_owners_by_path(rules)
      rules_by_path = rules.group_by { |owner| sanitised_path(owner[:path]) }
      reject_trailing_slash_conflicts(rules_by_path.keys)
      rules_by_path.map do |path, owners_for_path|
        [path, owners_for_path.map { |owner| owner[:owner] }.uniq.sort]
      end
    end

    # A path written both with and without a trailing slash is rejected rather
    # than guessed at: `/foo` and `/foo/` are effectively same rule, but on disk
    # they differ (a directory needs its slash to match recursively, a file must
    # not have one), so the definitions must pick one.
    def reject_trailing_slash_conflicts(paths)
      paths.group_by { |path| path.chomp('/') }.each_value do |variants|
        next if variants.uniq.size == 1

        raise "#{variants.min} is declared both with and without a trailing slash " \
              "(#{variants.uniq.sort.join(', ')}); pick one so it is clear whether it is a file or a directory."
      end
    end

    def path_depth(path)
      Pathname.new(path).each_filename.count
    end

    def blurb
      <<~BLURB
        This CODEOWNERS file is grouped by feature, using Github teams (a squad may
        have one or more Github teams).

        Please use the codeowners:generate rake task and the .cleo/codeowners yaml
        configuration files to update this file.
      BLURB
    end

    def sanitised_path(path)
      return path if path.start_with?('/')

      "/#{path}"
    end

    def validate_owners_in_features
      features_missing_from_features_yaml = files.keys - all_features
      return if features_missing_from_features_yaml.empty?

      raise "The following features are missing from features.yaml:\n#{
        features_missing_from_features_yaml.join("\n")
      }"
    end

    def blank?(value)
      return true if value.nil? || value == false
      return value.strip.empty? if value.is_a?(String)

      value.respond_to?(:empty?) && value.empty?
    end

    def present?(value)
      !blank?(value)
    end
  end
end
