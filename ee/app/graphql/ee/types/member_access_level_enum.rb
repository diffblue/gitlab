# frozen_string_literal: true

module EE
  module Types
    module MemberAccessLevelEnum
      extend ActiveSupport::Concern

      prepended do
        value 'MINIMAL_ACCESS', value: ::Gitlab::Access::MINIMAL_ACCESS, description: 'Minimal access.'
      end
    end
  end
end
