# frozen_string_literal: true

FactoryBot.define do
  factory :corpus, class: 'AppSec::Fuzzing::Coverage::Corpus' do
    user
    project
    package { association :package, project: project }
  end
end
