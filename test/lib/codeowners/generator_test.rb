# frozen_string_literal: true

require "fileutils"
require "test_helper"
require "tmpdir"

module Codeowners
  class GeneratorTest < Minitest::Test
    def setup
      @tmpdir = Pathname.new(Dir.mktmpdir)
      @definitions_dir = @tmpdir.join("definitions")
      @definitions_dir.mkpath
    end

    def teardown
      FileUtils.remove_entry(@tmpdir)
    end

    test "#call writes machine and human CODEOWNERS files with inherited owners" do
      write_definitions(
        features: <<~YAML,
          features:
            parent:
              child:
            sibling:
        YAML
        owners: <<~YAML,
          owners:
            parent: parent-team
            sibling: unowned
        YAML
        files: <<~YAML,
          files:
            parent:
              - /app/
            child:
              - /app/models/user.rb
            sibling:
              - /README.md
        YAML
      )

      run_generator

      assert_equal <<~CODEOWNERS, machine_output
        /app/ @meetcleo/parent-team
        /README.md @meetcleo/unowned
        /app/models/user.rb @meetcleo/parent-team
      CODEOWNERS

      assert_includes human_output, "# PARENT"
      assert_includes human_output, "# Currently owned by @meetcleo/parent-team"
      assert_includes human_output, "  /app/ @meetcleo/parent-team"
      assert_includes human_output, "  # CHILD"
      assert_includes human_output, "    /app/models/user.rb @meetcleo/parent-team"
      assert_includes human_output, "# SIBLING"
      assert_includes human_output, "# Currently unowned"
    end

    test "#call raises when a feature has no owner to inherit" do
      write_definitions(
        features: <<~YAML,
          features:
            orphan:
        YAML
        owners: <<~YAML,
          owners:
        YAML
        files: <<~YAML,
          files:
            orphan:
              - /orphan.rb
        YAML
      )

      error = assert_raises(RuntimeError) { run_generator }

      assert_equal "Please assign an owner for orphan in owners.yaml!", error.message
    end

    test "#call raises when file mappings reference features missing from features.yaml" do
      write_definitions(
        features: <<~YAML,
          features:
            known:
        YAML
        owners: <<~YAML,
          owners:
            known: known-team
        YAML
        files: <<~YAML,
          files:
            known:
              - /known.rb
            missing:
              - /missing.rb
        YAML
      )

      error = assert_raises(RuntimeError) { run_generator }

      assert_equal "The following features are missing from features.yaml:\nmissing", error.message
    end

    private

    attr_reader :definitions_dir, :tmpdir

    def write_definitions(features:, owners:, files:)
      definitions_dir.join("features.yaml").write(features)
      definitions_dir.join("owners.yaml").write(owners)
      definitions_dir.join("files.yaml").write(files)
    end

    def run_generator
      Generator.new(
        definitions_file: DefinitionsFile.new(definitions_dir.join("*.yaml").to_s),
        output_path: output_path,
        human_output_path: human_output_path,
      ).call
    end

    def output_path
      tmpdir.join("CODEOWNERS").to_s
    end

    def human_output_path
      tmpdir.join("CODEOWNERS-HUMAN").to_s
    end

    def machine_output
      File.read(output_path)
    end

    def human_output
      File.read(human_output_path)
    end
  end
end
