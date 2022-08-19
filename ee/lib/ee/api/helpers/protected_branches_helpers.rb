# frozen_string_literal: true

module EE
  module API
    module Helpers
      module ProtectedBranchesHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_params_ee do
            optional :unprotect_access_level,
              type: Integer,
              values: ::ProtectedBranch::UnprotectAccessLevel.allowed_access_levels,
              desc: 'Access levels allowed to unprotect (defaults: `40`, maintainer access level)'

            optional :allowed_to_push, type: Array, desc: 'An array of users/groups allowed to push' do
              optional :access_level, type: Integer, values: ::ProtectedBranch::PushAccessLevel.allowed_access_levels
              optional :user_id, type: Integer
              optional :group_id, type: Integer
            end

            optional :allowed_to_merge, type: Array, desc: 'An array of users/groups allowed to merge' do
              optional :access_level, type: Integer, values: ::ProtectedBranch::MergeAccessLevel.allowed_access_levels
              optional :user_id, type: Integer
              optional :group_id, type: Integer
            end

            optional :allowed_to_unprotect, type: Array, desc: 'An array of users/groups allowed to unprotect' do
              optional :access_level, type: Integer, values: ::ProtectedBranch::UnprotectAccessLevel.allowed_access_levels
              optional :user_id, type: Integer
              optional :group_id, type: Integer
            end

            optional :code_owner_approval_required, type: Grape::API::Boolean, default: false, desc: 'Prevent pushes to this branch if it matches an item in CODEOWNERS'
          end
        end
      end
    end
  end
end
