# frozen_string_literal: true

module EE
  module ProtectedBranch
    extend ActiveSupport::Concern

    prepended do
      has_and_belongs_to_many :approval_project_rules
      has_and_belongs_to_many :external_status_checks, class_name: '::MergeRequests::ExternalStatusCheck'

      has_many :required_code_owners_sections, class_name: "ProtectedBranch::RequiredCodeOwnersSection"

      protected_ref_access_levels :unprotect

      scope :preload_access_levels, -> { preload(:push_access_levels, :merge_access_levels, :unprotect_access_levels) }
    end

    class_methods do
      def branch_requires_code_owner_approval?(project, branch_name)
        return false unless project.code_owner_approval_required_available?

        ::Gitlab::SafeRequestStore["project-#{project.id}-branch-#{branch_name}".to_sym] ||=
          project.all_protected_branches.requiring_code_owner_approval.matching(branch_name).any?
      end
    end

    def code_owner_approval_required
      super && entity.code_owner_approval_required_available?
    end
    alias_method :code_owner_approval_required?, :code_owner_approval_required

    def can_unprotect?(user)
      return true if unprotect_access_levels.empty?

      unprotect_access_levels.any? do |access_level|
        access_level.check_access(user)
      end
    end

    def supports_unprotection_restrictions?
      return false if group

      project.licensed_feature_available?(:unprotection_restrictions)
    end

    def inherited?
      !namespace_id.nil?
    end
    alias_method :inherited, :inherited?
  end
end
