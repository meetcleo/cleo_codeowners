# frozen_string_literal: true

require_relative "cleo_codeowners/version"
require_relative "codeowners"
require_relative "cleo_codeowners/railtie" if defined?(Rails::Railtie)
