# frozen_string_literal: true

FactoryBot.modify do
  factory :issue do
    trait :published do
      after(:create) do |issue|
        issue.create_status_page_published_incident!
      end
    end

    trait :with_sla do
      issuable_sla
    end
  end
end

# There is another factory called :requirement for RequirementManagement::Requirement.
# We are converting that class into an issue type. We can rename this as :requirement
# when migration is completed. More information at https://gitlab.com/gitlab-org/gitlab/-/issues/323779
FactoryBot.define do
  factory :requirement_issue, parent: :issue do
    issue_type { :requirement }
  end
end

FactoryBot.define do
  factory :quality_test_case, parent: :issue do
    issue_type { :test_case }
  end
end
