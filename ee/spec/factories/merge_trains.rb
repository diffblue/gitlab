# frozen_string_literal: true

FactoryBot.define do
  factory :merge_train_car, class: 'MergeTrains::Car' do
    target_branch { 'master' }
    target_project factory: :project
    merge_request
    user
    pipeline factory: :ci_pipeline

    trait :idle do
      status { MergeTrains::Car.state_machines[:status].states[:idle].value }
    end

    trait :merged do
      status { MergeTrains::Car.state_machines[:status].states[:merged].value }
    end

    trait :merging do
      status { MergeTrains::Car.state_machines[:status].states[:merging].value }
    end

    trait :stale do
      status { MergeTrains::Car.state_machines[:status].states[:stale].value }
    end

    trait :fresh do
      status { MergeTrains::Car.state_machines[:status].states[:fresh].value }
    end
  end
end
