# frozen_string_literal: true

require 'codeowners'

namespace :codeowners do
  desc 'Generates CODEOWNERS file from .cleo/codeowners'
  task generate: [:environment] do
    Codeowners::Generator.new.call
  end
end
