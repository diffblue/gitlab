# frozen_string_literal: true

module EE
  module ProtectedBranches
    module LegacyApiUpdateService
      extend ::Gitlab::Utils::Override
      prepend BlockedByPolicy

      private

      # If a protected branch can have more than one access level (EE), only
      # remove the relevant access levels. If we don't do this, we'll have a
      # failed validation.
      override :delete_redundant_access_levels
      def delete_redundant_access_levels
        case developers_can_merge
        when true
          protected_branch.merge_access_levels.developer.destroy_all # rubocop: disable Cop/DestroyAll
        when false
          protected_branch.merge_access_levels.developer.destroy_all # rubocop: disable Cop/DestroyAll
          protected_branch.merge_access_levels.maintainer.destroy_all # rubocop: disable Cop/DestroyAll
        end

        case developers_can_push
        when true
          protected_branch.push_access_levels.developer.destroy_all # rubocop: disable Cop/DestroyAll
        when false
          protected_branch.push_access_levels.developer.destroy_all # rubocop: disable Cop/DestroyAll
          protected_branch.push_access_levels.maintainer.destroy_all # rubocop: disable Cop/DestroyAll
        end
      end
    end
  end
end
