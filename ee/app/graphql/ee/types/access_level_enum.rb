# frozen_string_literal: true

module EE
  module Types
    module AccessLevelEnum
      extend ActiveSupport::Concern

      prepended do
        value 'ADMIN', value: ::Gitlab::Access::ADMIN, description: 'Admin access.'
      end
    end
  end
end
