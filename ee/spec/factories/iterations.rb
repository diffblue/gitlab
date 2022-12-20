# frozen_string_literal: true

FactoryBot.define do
  sequence(:sequential_date) do |n|
    n.days.from_now
  end

  factory :iteration do
    start_date { generate(:sequential_date) }
    due_date { generate(:sequential_date) }

    transient do
      iterations_cadence { nil }
      project { nil }
      group { nil }
      project_id { nil }
      group_id { nil }
      resource_parent { nil }
    end

    trait :with_title do
      title
    end

    trait :upcoming do
      state_enum { Iteration::STATE_ENUM_MAP[:upcoming] }
    end

    trait :current do
      state_enum { Iteration::STATE_ENUM_MAP[:current] }
    end

    trait :closed do
      state_enum { Iteration::STATE_ENUM_MAP[:closed] }
      start_date { 1.week.ago }
      due_date   { 1.week.ago + 4.days }
    end

    trait(:skip_future_date_validation) do
      after(:stub, :build) do |iteration|
        iteration.skip_future_date_validation = true
      end
    end

    trait(:with_due_date) do
      after(:stub, :build) do |iteration, evaluator|
        iteration.due_date = evaluator.start_date + 4.days if evaluator.start_date.present?
      end
    end

    after(:build, :stub) do |iteration, evaluator|
      if evaluator.group
        iteration.group = evaluator.group
      elsif evaluator.group_id
        iteration.group_id = evaluator.group_id
      elsif evaluator.project
        iteration.project = evaluator.project
      elsif evaluator.project_id
        iteration.project_id = evaluator.project_id
      elsif evaluator.resource_parent
        id = evaluator.resource_parent.id
        evaluator.resource_parent.is_a?(Group) ? evaluator.group_id = id : evaluator.project_id = id
      else
        iteration.group = create(:group)
      end

      if evaluator.iterations_cadence.present?
        iteration.iterations_cadence = evaluator.iterations_cadence
        # TODO https://gitlab.com/gitlab-org/gitlab/-/issues/296100
        # group_id will be removed from sprints and we won't need this feature.
        iteration.group = evaluator.iterations_cadence.group unless evaluator.group.present?
      else
        iteration.iterations_cadence = iteration.group.iterations_cadences.first || create(:iterations_cadence, group: iteration.group) if iteration.group
        iteration.iterations_cadence = create(:iterations_cadence, group_id: iteration.group_id) if iteration.group_id
      end
    end

    factory :upcoming_iteration, traits: [:upcoming]
    factory :current_iteration, traits: [:current]
    factory :closed_iteration, traits: [:closed]
  end
end
