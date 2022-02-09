# frozen_string_literal: true

FactoryBot.define do
  factory :corpus, class: 'AppSec::Fuzzing::Coverage::Corpus' do
    user
    project
    package { association(:generic_package, :with_zip_file, project: project, status: :hidden) }
  end
end
