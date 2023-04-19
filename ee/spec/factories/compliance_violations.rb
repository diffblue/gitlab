# frozen_string_literal: true

FactoryBot.define do
  factory :compliance_violation, class: 'MergeRequests::ComplianceViolation' do
    violating_user factory: :user
    reason { :approved_by_merge_request_author }
    merge_request

    merged_at { merge_request.merged_at }
    target_project_id { merge_request.target_project_id }
    title { merge_request.title }
    target_branch { merge_request.target_branch }

    trait :approved_by_merge_request_author do
      reason { :approved_by_merge_request_author }
      severity_level { :high }
    end

    trait :approved_by_committer do
      reason { :approved_by_committer }
      severity_level { :high }
    end

    trait :approved_by_insufficient_users do
      reason { :approved_by_insufficient_users }
      severity_level { :high }
    end
  end
end
