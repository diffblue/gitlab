# frozen_string_literal: true

module Projects
  class AllBranchesRule < BranchRule
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def any_rules?
      approval_project_rules.present? || external_status_checks.present?
    end

    def name
      s_('All branches')
    end

    def default_branch?
      false
    end

    def protected?
      false
    end

    def branch_protection
      nil
    end

    def can_unprotect?
      false
    end

    def group
      nil
    end

    def matching_branches_count
      project.repository.branch_count
    end

    def created_at
      [
        *external_status_checks.map(&:created_at),
        *approval_project_rules.map(&:created_at)
      ].min
    end

    def updated_at
      [
        *external_status_checks.map(&:updated_at),
        *approval_project_rules.map(&:updated_at)
      ].max
    end

    def approval_project_rules
      project.approval_rules.for_all_branches
    end

    def external_status_checks
      project.external_status_checks.for_all_branches
    end
  end
end
