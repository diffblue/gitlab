# frozen_string_literal: true

module EE
  module API
    module Entities
      # Being used in private project-level approvals API.
      # This overrides the `eligible_approvers` to be exposed as `approvers`.
      #
      # To be removed in https://gitlab.com/gitlab-org/gitlab/issues/13574.
      class ProjectApprovalSettingRule < ProjectApprovalRule
        expose :approvers, using: ::API::Entities::UserBasic, override: true
        expose :scanners, override: true
        expose :vulnerabilities_allowed, override: true
        expose :severity_levels, override: true
        expose :vulnerability_states, override: true
      end
    end
  end
end
