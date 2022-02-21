# frozen_string_literal: true

FactoryBot.define do
  factory :related_epic_link, class: 'Epic::RelatedEpicLink' do
    source factory: :epic
    target factory: :epic
  end
end
