# typed: false
# frozen_string_literal: true

require 'json'
require 'open3'
require_relative 'definitions_file'

module Codeowners
  class ContributorFinder
    DEFAULT_MAX_COMMITS = 50

    ContributorStats = Data.define(:additions, :deletions, :commits, :dates)
    Contributor = Data.define(:email, :username, :lines_changed, :additions, :deletions, :commits, :first_commit_date,
                              :last_commit_date)

    def initialize(definitions_file: DefinitionsFile.new, max_commits: DEFAULT_MAX_COMMITS)
      @definitions_file = definitions_file
      @max_commits = max_commits
      @email_to_username_cache = {}
    end

    def find_contributors(feature:)
      file_paths = collect_feature_files(feature)

      return [] if file_paths.empty?

      contributors = analyse_git_history(file_paths)
      contributors.sort_by(&:lines_changed).reverse
    end

    private

    attr_reader :definitions_file, :max_commits, :email_to_username_cache

    def collect_feature_files(feature)
      files = definitions_file.feature_paths(feature:)

      subfeatures = find_all_subfeatures(feature)
      subfeatures.each do |subfeature|
        files.concat(definitions_file.feature_paths(feature: subfeature))
      end

      files.uniq.map(&:to_s)
    end

    def find_all_subfeatures(parent_feature, collected = [])
      features_config = definitions_file.features_config
      return collected unless features_config[parent_feature].is_a?(Hash)

      features_config[parent_feature].each_key do |subfeature|
        collected << subfeature
        find_all_subfeatures(subfeature, collected)
      end

      collected
    end

    def analyse_git_history(file_paths)
      return [] if file_paths.empty?

      max_commits_str = max_commits.to_i
      # Format: commit_hash|author_email|date
      # Followed by numstat lines: additions\tdeletions\tfilename
      git_args = ['git', 'log', '--numstat', "--max-count=#{max_commits_str}", '--format=%H|%ae|%ad', '--date=short',
                  '--']
      git_args.concat(file_paths)

      output, status = Open3.capture2(*git_args, err: %i[child out])
      unless status.success?
        warn('Failed to run git log', output:)
        return []
      end

      parse_git_log(output)
    end

    # Parses git log output in the format:
    # commit_hash|email|date
    # <blank line>
    # additions\tdeletions\tfilename
    # additions\tdeletions\tfilename
    # <blank line>
    # commit_hash|email|date
    # ...
    def parse_git_log(output)
      contributors_by_email = Hash.new { ContributorStats.new(additions: 0, deletions: 0, commits: 0, dates: []) }

      current_email = nil
      output.each_line do |line|
        line.strip!
        next if line.empty?

        if commit_line?(line)
          current_email = parse_commit_line(line, contributors_by_email)
        elsif numstat_line?(line) && current_email
          parse_numstat_line(line, contributors_by_email, current_email)
        end
      end

      build_contributor_records(contributors_by_email)
    end

    def commit_line?(line)
      line.include?('|')
    end

    def parse_commit_line(line, contributors_by_email)
      _commit_hash, email, date = line.split('|')
      stats = contributors_by_email[email]
      contributors_by_email[email] = stats.with(
        commits: stats.commits + 1,
        dates: stats.dates + [date]
      )
      email
    end

    def numstat_line?(line)
      line.match?(/^\d+\s+\d+\s+/)
    end

    def parse_numstat_line(line, contributors_by_email, email)
      additions, deletions = line.split(/\s+/)
      # Binary files show '-' for additions/deletions, skip them
      return if additions == '-' || deletions == '-'

      stats = contributors_by_email[email]
      contributors_by_email[email] = stats.with(
        additions: stats.additions + additions.to_i,
        deletions: stats.deletions + deletions.to_i
      )
    end

    def build_contributor_records(contributors_by_email)
      contributors_by_email.map do |email, stats|
        Contributor.new(
          email:,
          username: resolve_email_to_username(email),
          lines_changed: stats.additions + stats.deletions,
          additions: stats.additions,
          deletions: stats.deletions,
          commits: stats.commits,
          first_commit_date: stats.dates.min,
          last_commit_date: stats.dates.max
        )
      end
    end

    def resolve_email_to_username(email)
      return email_to_username_cache[email] if email_to_username_cache.key?(email)

      username = fetch_github_username(email)
      email_to_username_cache[email] = username
      username
    end

    def fetch_github_username(email)
      query_param = "author-email:#{email}+repo:meetcleo/meetcleo"
      gh_args = [
        'gh', 'api',
        "/search/commits?q=#{query_param}",
        '--jq', '.items[0].author.login'
      ]

      result, status = Open3.capture2(*gh_args, err: File::NULL)
      result = result.strip

      if status.success? && !result.empty? && result != 'null'
        result
      else
        email.split('@').first
      end
    end
  end
end
