# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    module Cvss
      class Parameter
        attr_reader :key, :value

        def initialize(key:, valid_values:)
          @key = key
          @valid_values = valid_values
        end

        def set(given)
          return "`#{given}` is not a valid value for `#{key}`" unless valid_values.include?(given)

          @value = given
          nil
        end

        private

        attr_reader :valid_values
      end
    end
  end
end
