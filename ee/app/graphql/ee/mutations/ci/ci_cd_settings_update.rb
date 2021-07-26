# frozen_string_literal: true

module EE
  module Mutations
    module Ci
      module CiCdSettingsUpdate
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :merge_pipelines_enabled, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates if merge pipelines are enabled for the project.'

          argument :merge_trains_enabled, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates if merge trains are enabled for the project.'
        end
      end
    end
  end
end
