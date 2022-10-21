# frozen_string_literal: true

FactoryBot.define do
  factory :protected_environment_approval_rule, class: 'ProtectedEnvironments::ApprovalRule' do
    protected_environment
    required_approvals { 1 }
    # Define association only if access level and group is not null to mimic DB constraint.
    user { |e| association(:user) unless e.access_level || e.group || e.group_id }

    trait :maintainer_access do
      access_level { Gitlab::Access::MAINTAINER }
    end

    trait :developer_access do
      access_level { Gitlab::Access::DEVELOPER }
    end
  end
end
