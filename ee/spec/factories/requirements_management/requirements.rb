# frozen_string_literal: true

FactoryBot.define do
  factory :requirement, class: 'RequirementsManagement::Requirement' do
    project
    author
    title { generate(:title) }
    title_html { "<h2>#{title}</h2>" }
    requirement_issue do
      issue_state = state.to_s == 'archived' ? 'closed' : 'opened'
      association(:issue, issue_type: :requirement, project: project, author: author, title: title, description: description, state: issue_state)
    end
  end
end
