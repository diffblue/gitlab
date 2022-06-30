# frozen_string_literal: true

module EE
  module ProjectGroupLink
    extend ActiveSupport::Concern

    prepended do
      scope :in_project, -> (projects) { where(project: projects) }
      scope :not_in_group, -> (groups) { where.not(group: groups) }

      before_destroy :delete_related_access_levels

      validate :group_with_allowed_email_domains
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

    def group_with_allowed_email_domains
      return unless shared_from&.group && shared_with_group

      root_ancestor_group_domains = shared_from.root_ancestor.allowed_email_domains.pluck(:domain).to_set
      return if root_ancestor_group_domains.empty?

      shared_with_group_domains = shared_with_group.root_ancestor_allowed_email_domains.pluck(:domain).to_set

      if shared_with_group_domains.empty? || !shared_with_group_domains.subset?(root_ancestor_group_domains)
        errors.add(:group_id,
        _("Invited group allowed email domains must contain a subset of the allowed email domains"\
          " of the root ancestor group. Go to the group's 'Settings &gt; General' page"\
          " and check 'Restrict membership by email domain'."))
      end
    end
  end
end
