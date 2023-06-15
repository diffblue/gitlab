# frozen_string_literal: true

FactoryBot.define do
  factory :index_status do
    project { association(:project, :repository) }
    indexed_at { Time.now }
    last_commit { project.commit.sha }
  end
end
