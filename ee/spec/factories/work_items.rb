# frozen_string_literal: true

FactoryBot.modify do
  factory :work_item do
    trait :requirement do
      issue_type { :requirement }
      association :work_item_type, :default, :requirement
    end

    trait :satisfied_status do
      issue_type { :requirement }
      association :work_item_type, :default, :requirement

      after(:create) do |work_item|
        create(:test_report, requirement_issue: work_item, state: :passed)
      end
    end

    trait :failed_status do
      issue_type { :requirement }
      association :work_item_type, :default, :requirement

      after(:create) do |work_item|
        create(:test_report, requirement_issue: work_item, state: :failed)
      end
    end

    after(:build) do |work_item|
      next unless work_item.requirement?

      work_item.build_requirement(project: work_item.project)
    end
  end
end
