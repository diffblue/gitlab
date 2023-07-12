# frozen_string_literal: true

module EE
  module Types
    module ProjectStatisticsType
      extend ActiveSupport::Concern

      prepended do
        field :cost_factored_storage_size, GraphQL::Types::Float, null: false,
          alpha: { milestone: '16.2' },
          description: 'Storage size in bytes with any applicable cost factor for forks applied. ' \
                       'This will equal storage_size if there is no applicable cost factor.'
      end
    end
  end
end
