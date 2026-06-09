# frozen_string_literal: true

require "active_support/core_ext/enumerable"
require "active_support/core_ext/string/inflections"
require "English"
require "pathname"
require "set"
require "thor"
require_relative "../codeowners"

module Codeowners
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "find_files feature (glob)", "Find all files under a particular feature, matching the GLOB file pattern"
    def find_files(feature, glob = "*")
      files = DefinitionsFile.new.feature_paths(feature:).select { |file| file.fnmatch?(glob) }
      puts files.join("\n")
    end

    desc "find_test_files feature", "Find all test files under a particular feature"
    def find_test_files(feature)
      find_files(feature, "*_test.rb")
    end

    desc "find_contributors FEATURE", "Find top contributors for a feature based on git history"
    method_option :max_commits, type: :numeric, default: 50, desc: "Maximum number of commits to analyze"
    def find_contributors(feature)
      contributor_finder = ContributorFinder.new(max_commits: options[:max_commits])
      contributors = contributor_finder.find_contributors(feature:)

      if contributors.empty?
        puts "No contributors found for feature '#{feature}'"
        exit(0)
      end

      first_date = contributors.filter_map(&:first_commit_date).min
      last_date = contributors.filter_map(&:last_commit_date).max
      date_range = first_date && last_date ? "#{first_date} to #{last_date}" : "N/A"
      total_commits = contributors.sum(&:commits)

      puts "Top contributors for feature '#{feature}'"
      puts "Analyzed: last #{options[:max_commits]} commits (#{date_range})"
      puts "Total commits: #{total_commits}"
      puts

      table_format = "%-30s %10s %10s %15s %8s"
      puts format(table_format, "GitHub Username", "Additions", "Deletions", "Lines Changed", "Commits")
      puts "-" * 81
      contributors.each do |contributor|
        puts format(
          table_format,
          contributor.username,
          contributor.additions,
          contributor.deletions,
          contributor.lines_changed,
          contributor.commits,
        )
      end
    end

    desc "find_owner filepath", "Find who owns a given file"
    method_option :glob, type: :boolean, aliases: "-g", desc: "Output the pattern matched"
    def find_owner(filepath)
      codeowners_file = CodeownersFile.new
      owner_finder = OwnerFinder.new(codeowners_file:)
      ownership = owner_finder.find_ownership_for_file(filepath:)
      owners = ownership&.owners

      unless owners&.any?
        puts "No owners found!"
        exit(1)
      end

      output = owners.join(" ")
      output << " #{ownership.glob}" if options[:glob]

      puts output
    end

    desc "find_owned_files OWNER", "Find files matched to a given OWNER in the CODEOWNERS file"
    method_option :pattern, type: :string, default: "**/*", desc: "Pattern to match files against"
    def find_owned_files(owner)
      warn_against_global_glob_pattern if options[:pattern] == "**/*"

      codeowners_file = CodeownersFile.new
      owner_finder = OwnerFinder.new(codeowners_file:)
      owned_files = Dir.glob(options[:pattern]).select do |filepath|
        next unless Pathname.new(filepath).file?
        next unless owner_finder.find_owners_for_file(filepath:).include?(owner)

        filepath
      end

      owner_long_name = Owner.new(owner).long_name
      if owned_files.any?
        puts "#{owned_files.length} #{'file'.pluralize(owned_files.length)} found belonging to owner #{owner_long_name}"
        puts owned_files
      else
        puts "No files found belonging to owner #{owner_long_name}"
      end
    end

    desc "find_unowned_files", "Find files in the repo that are not marked with an owner in CODEOWNERS"
    method_option :pattern, type: :string, default: "**/*", desc: "Pattern to match files against"
    method_option :exit_status_on_match, type: :numeric, default: 0, desc: "What exit status should I return on match?"
    method_option :output, type: :string, aliases: "-o", desc: "Output file path (disables color codes)"
    def find_unowned_files
      warn_against_global_glob_pattern if options[:pattern] == "**/*"

      codeowners_file = CodeownersFile.new
      pattern = options[:pattern]

      git_ls_files_pattern = pattern == "**/*" ? "." : pattern
      git_tracked_files = %x(git ls-files #{git_ls_files_pattern} 2>&1)
      unless $CHILD_STATUS.success?
        warn "Failed to run git ls-files: #{git_tracked_files}"
        exit(1)
      end

      filepaths = git_tracked_files.split("\n").select do |filepath|
        filepath_obj = Pathname.new(filepath)
        next if filepath_obj.directory?

        codeowners_file.globs.none? { |glob| glob.match?(filepath) }
      end

      output_stream = options[:output] ? File.open(options[:output], "w") : $stdout
      use_colors = options[:output].nil?

      begin
        if filepaths.empty?
          output_with_color(output_stream, use_colors, "\e[32m", "No unowned files found in #{options[:pattern]}")
          exit(0)
        else
          truncated_paths = truncate_to_unowned_directories(filepaths)
          output_with_color(output_stream, use_colors, "\e[31m", "The following #{'path'.pluralize(truncated_paths.length)} are not included in the CODEOWNERS file:")
          truncated_paths.each do |filepath|
            output_with_color(output_stream, use_colors, "\e[31m", filepath)
          end
          exit(options[:exit_status_on_match])
        end
      ensure
        output_stream.close if options[:output]
      end
    end

    desc "find_feature filepath", "Find which feature a given file belongs to"
    def find_feature(filepath)
      feature = DefinitionsFile.new.find_feature_for_file(path: filepath)
      if feature
        puts feature
      else
        puts "No feature found for #{filepath}"
        exit(1)
      end
    end

    desc "find_features filepath", "Find all matching features a given file belongs to"
    method_option :show_path, type: :boolean, default: false, desc: "Print the path (useful when finding many paths)"
    def find_features(filepath)
      feature_matches = DefinitionsFile.new.find_features_for_file(path: filepath)
      if feature_matches.any?
        feature_matches.each do |match|
          print = []
          print << filepath if options[:show_path]
          print << match.feature
          print << match.path_pattern
          puts print.join(",")
        end
      else
        puts "No feature found for #{filepath}"
        exit(1)
      end
    end

    private

    def output_with_color(stream, use_colors, color_code, text)
      if use_colors
        stream.puts "#{color_code} #{text} \e[0m"
      else
        stream.puts text
      end
    end

    def truncate_to_unowned_directories(filepaths)
      return [] if filepaths.empty?

      unowned_set = filepaths.to_set
      result = []
      processed_dirs = Set.new

      directories = filepaths.map { |filepath| File.dirname(filepath) }.uniq.sort_by { |directory| directory.count("/") }

      directories.each do |directory|
        next if directory == "."
        next if processed_dirs.any? { |processed| directory.start_with?("#{processed}/") }

        git_files_in_dir = `git ls-files -- '#{directory}/' 2>&1`.split("\n")
        next unless $CHILD_STATUS.success?
        next if git_files_in_dir.empty?

        git_files_in_dir.select! { |file| File.file?(file) }

        if git_files_in_dir.all? { |file| unowned_set.include?(file) }
          result << "#{directory}/"
          processed_dirs << directory
        end
      end

      filepaths.each do |filepath|
        result << filepath unless processed_dirs.any? { |directory| filepath.start_with?("#{directory}/") }
      end

      result.sort.uniq
    end

    def warn_against_global_glob_pattern
      warn <<~WARNING
        Scanning all files in this repository (--pattern=**/*) may take a while...
        You may want to use a specific glob pattern e.g. (--pattern=app/models/**/*.rb)
      WARNING
    end
  end
end
