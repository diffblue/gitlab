# frozen_string_literal: true

FactoryBot.define do
  factory :corpus, class: 'AppSec::Fuzzing::Coverage::Corpus' do
    user
    package
    project
  end
end
