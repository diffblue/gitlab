# frozen_string_literal: true

module EE
  module Types
    module Ci
      module CiCdSettingType
        extend ActiveSupport::Concern

        prepended do
          field :merge_trains_skip_train_allowed,
            GraphQL::Types::Boolean,
            null: false,
            description: 'Whether merge immediately is allowed for merge trains.',
            method: :merge_trains_skip_train_allowed?
        end
      end
    end
  end
end
