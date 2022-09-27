# frozen_string_literal: true

FactoryBot.define do
  factory :requirement, class: 'RequirementsManagement::Requirement' do
    project

    transient do
      author { create(:user) } # rubocop:disable FactoryBot/InlineAssociation
      state { 'opened' }
      title { generate(:title) }
      description { FFaker::Lorem.sentence }
      created_at { Time.current }
      updated_at { Time.current }
    end

    requirement_issue do
      issue_state = state.to_s == 'archived' ? 'closed' : 'opened'
      association(:issue, issue_type: :requirement, project: project, author:
                  author, title: title, description: description, state:
                  issue_state, created_at: created_at, updated_at: updated_at)
    end
  end
end
