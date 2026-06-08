# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "mocha/minitest"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "cleo_codeowners"

module CleoCodeownersTestExtensions
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def test(test_name, &)
      define_method(:"test_#{test_name.gsub(/\s+/, '_')}", &)
    end
  end

  def described_class
    Object.const_get(self.class.name.sub(/Test\Z/, ""))
  end
end

Minitest::Test.include(CleoCodeownersTestExtensions)
