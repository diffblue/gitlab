# frozen_string_literal: true

FactoryBot.modify do
  factory :work_item do
    trait :requirement do
      issue_type { :requirement }
      association :work_item_type, :default, :requirement
    end

    trait :test_case do
      issue_type { :test_case }
      association :work_item_type, :default, :test_case
    end

    trait :objective do
      issue_type { :objective }
      association :work_item_type, :default, :objective
    end

    trait :key_result do
      issue_type { :key_result }
      association :work_item_type, :default, :key_result
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
      next unless work_item.work_item_type.requirement?

      work_item.build_requirement(project: work_item.project)
    end
  end
end
