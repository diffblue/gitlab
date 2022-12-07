# frozen_string_literal: true

# Casts input from a SCIM compValue to a ruby object
# This should be updated to accept the following JSON style inputs:
#   false / null / true / number / string
#
# It also needs to accept capitalized True/False from Azure
#
# See https://www.rfc-editor.org/rfc/rfc7644#section-3.4.2.2
module EE
  module Gitlab
    module Scim
      class ValueParser
        COERCED_VALUES = {
          'true' => true,
          'false' => false
        }.freeze

        def initialize(input)
          @input = input
        end

        def type_cast
          return @input unless @input.is_a?(String)

          COERCED_VALUES.fetch(unquoted.downcase, unquoted)
        end

        private

        def unquoted
          @unquoted ||= @input.delete('\"')
        end
      end
    end
  end
end
