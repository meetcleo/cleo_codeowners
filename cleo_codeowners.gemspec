# frozen_string_literal: true

require_relative 'lib/cleo_codeowners/version'

Gem::Specification.new do |spec|
  spec.name = 'cleo_codeowners'
  spec.version = CleoCodeowners::VERSION
  spec.authors = %w[@agentAngelope @bodacious @sldblog]

  spec.summary = 'Cleo CODEOWNERS tooling'
  spec.description = 'Tools for reading Cleo CODEOWNERS definitions and generating GitHub CODEOWNERS files.'
  spec.homepage = 'https://github.com/meetcleo/meetcleo'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files =
    Dir.glob("{#{File.basename(__FILE__)},README.md,lib/**/*,exe/*}", File::FNM_DOTMATCH).select do |path|
      File.file?(path) && !File.symlink?(path)
    end

  spec.bindir = 'exe'
  spec.executables = ['cleo-codeowners']
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'rake'
  spec.add_dependency 'thor'
end
