# frozen_string_literal: true

FactoryBot.define do
  factory :insight do
    group
    project
  end

  factory :insights_issues_by_team, class: 'Hash' do
    initialize_with do
      {
        Manage: 1,
        Plan: 3,
        Create: 2,
        undefined: 1
      }.with_indifferent_access
    end

    skip_create
  end

  factory :insights_merge_requests_per_month, class: 'Hash' do
    initialize_with do
      {
        'January 2019' => 1,
        'February 2019' => 2,
        'March 2019' => 3
      }
    end

    skip_create
  end

  factory :insights_issues_by_team_per_month, class: 'Hash' do
    initialize_with do
      {
        'January 2019' => {
          Manage: 1,
          Plan: 1,
          Create: 1,
          undefined: 0
        }.with_indifferent_access,
        'February 2019' => {
          Manage: 0,
          Plan: 1,
          Create: 0,
          undefined: 0
        }.with_indifferent_access,
        'March 2019' => {
          Manage: 0,
          Plan: 1,
          Create: 1,
          undefined: 1
        }.with_indifferent_access
      }
    end

    skip_create
  end
end
