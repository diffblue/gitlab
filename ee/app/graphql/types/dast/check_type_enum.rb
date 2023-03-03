# frozen_string_literal: true

module Types
  module Dast
    class CheckTypeEnum < BaseEnum
      graphql_name 'DastPreScanVerificationCheckType'
      description 'Check type of the pre scan verification step.'

      ::Dast::PreScanVerificationStep.check_types.each_key do |check_type|
        value check_type.upcase, value: check_type, description: "#{check_type.titleize} check"
      end
    end
  end
end
