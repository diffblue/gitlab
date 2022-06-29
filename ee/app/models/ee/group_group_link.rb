# frozen_string_literal: true

module EE
  module GroupGroupLink
    extend ActiveSupport::Concern

    prepended do
      scope :in_shared_group, -> (shared_groups) { where(shared_group: shared_groups) }
      scope :not_in_shared_with_group, -> (shared_with_groups) { where.not(shared_with_group: shared_with_groups) }

      validate :group_with_allowed_email_domains
    end

    private

    def group_with_allowed_email_domains
      return unless shared_group && shared_with_group

      shared_group_domains = shared_group.root_ancestor_allowed_email_domains.pluck(:domain).to_set
      return if shared_group_domains.empty?

      shared_with_group_domains = shared_with_group.root_ancestor_allowed_email_domains.pluck(:domain).to_set

      if shared_with_group_domains.empty? || !shared_with_group_domains.subset?(shared_group_domains)
        errors.add(:group_id, _("Invited group allowed email domains must contain a subset of the allowed"\
          " email domains of the root ancestor group. Go to the group's 'Settings &gt; General' page"\
          " and check 'Restrict membership by email domain'."))
      end
    end
  end
end
