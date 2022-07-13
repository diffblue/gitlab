# frozen_string_literal: true

module EE
  module API
    module Helpers
      module ProtectedTagsHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_params_ee do
            optional :allowed_to_create, type: Array, desc: 'An array of users/groups allowed to create' do
              optional :access_level, type: Integer, values: ::ProtectedTag::CreateAccessLevel.allowed_access_levels
              optional :user_id, type: Integer
              optional :group_id, type: Integer
            end
          end
        end
      end
    end
  end
end
