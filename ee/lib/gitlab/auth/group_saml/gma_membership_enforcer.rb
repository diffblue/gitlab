# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class GmaMembershipEnforcer
        def initialize(project)
          @project = project
        end

        def can_add_user?(user)
          return true if user.project_bot?

          check_project_membership(user) && check_source_project_membership(user)
        end

        private

        attr_reader :project

        def check_project_membership(user)
          check_group_managed_account(project.root_ancestor, user)
        end

        def check_source_project_membership(user)
          return true unless project.forked?
          return true unless project.forked_from_project

          check_group_managed_account(project.forked_from_project.root_ancestor, user)
        end

        def check_group_managed_account(root_ancestor, user)
          return true unless root_ancestor.is_a?(Group) && root_ancestor.enforced_group_managed_accounts?

          root_ancestor == user.managing_group
        end
      end
    end
  end
end
