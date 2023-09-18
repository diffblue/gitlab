# frozen_string_literal: true

module EE
  module ProjectMemberPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:security_policy_bot) { @subject.user&.security_policy_bot? }

      rule { security_policy_bot }.policy do
        prevent :destroy_project_member
      end
    end
  end
end
