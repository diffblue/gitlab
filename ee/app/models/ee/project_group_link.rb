# frozen_string_literal: true

module EE
  module ProjectGroupLink
    extend ActiveSupport::Concern

    prepended do
      before_destroy :delete_related_access_levels
    end

    def delete_related_access_levels
      return unless group.present? && project.present?

      # For protected branches
      project.protected_branches.merge_access_by_group(group).destroy_all # rubocop: disable Cop/DestroyAll
      project.protected_branches.push_access_by_group(group).destroy_all # rubocop: disable Cop/DestroyAll

      # For protected tags
      project.protected_tags.create_access_by_group(group).delete_all

      # For protected environments
      project.protected_environments.revoke_group(group)
    end
  end
end
