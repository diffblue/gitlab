# frozen_string_literal: true

FactoryBot.define do
  factory :approval_merge_request_rule do
    merge_request
    sequence(:name) { |n| "#{ApprovalRuleLike::DEFAULT_NAME}-#{n}" }
  end

  factory :approval_merge_request_rule_source do
    approval_merge_request_rule
    approval_project_rule
  end

  factory :code_owner_rule, parent: :approval_merge_request_rule do
    merge_request
    rule_type { :code_owner }
    sequence(:name) { |n| "*-#{n}.js" }
    section { Gitlab::CodeOwners::Section::DEFAULT }
  end

  factory :report_approver_rule, parent: :approval_merge_request_rule do
    merge_request
    rule_type { :report_approver }
    report_type { :license_scanning }
    sequence(:name) { |n| "*-#{n}.js" }

    trait :requires_approval do
      approvals_required { rand(1..ApprovalProjectRule::APPROVALS_REQUIRED_MAX) }
    end

    trait :license_scanning do
      name { ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT }
      report_type { :license_scanning }
    end

    trait :code_coverage do
      name { ApprovalRuleLike::DEFAULT_NAME_FOR_COVERAGE }
      report_type { :code_coverage }
    end

    trait :scan_finding do
      sequence(:name) { |n| "Scan finding #{n}" }
      report_type { :scan_finding }
    end
  end

  factory :any_approver_rule, parent: :approval_merge_request_rule do
    rule_type { :any_approver }
    name { "All Members" }
  end

  factory :approval_project_rule do
    project
    sequence(:name) { |n| "#{ApprovalRuleLike::DEFAULT_NAME}-#{n}" }
    rule_type { :regular }

    trait :any_approver_rule do
      rule_type { :any_approver }
      name { "All Members" }
    end

    trait :requires_approval do
      approvals_required { rand(1..ApprovalProjectRule::APPROVALS_REQUIRED_MAX) }
    end

    trait :license_scanning do
      name { ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT }
      rule_type { :report_approver }
      report_type { :license_scanning }
    end

    trait :code_coverage do
      name { ApprovalRuleLike::DEFAULT_NAME_FOR_COVERAGE }
      rule_type { :report_approver }
      report_type { :code_coverage }
    end

    trait :scan_finding do
      sequence(:name) { |n| "Scan finding #{n}" }
      rule_type { :report_approver }
      report_type { :scan_finding }
      applies_to_all_protected_branches { true }
    end
  end

  factory :approval_project_rules_protected_branch do
    approval_project_rule
    protected_branch
  end

  factory :approval_project_rules_user do
    approval_project_rule
    user
  end
end
