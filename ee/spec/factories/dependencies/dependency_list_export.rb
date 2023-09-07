# frozen_string_literal: true

FactoryBot.define do
  factory :dependency_list_export, class: 'Dependencies::DependencyListExport' do
    project
    author
    status { 0 }
    export_type { :dependency_list }

    trait :with_file do
      file { fixture_file_upload('ee/spec/fixtures/dependencies/dependencies.json') }
    end

    trait :running do
      status { 1 }
    end

    trait :finished do
      file { fixture_file_upload('ee/spec/fixtures/dependencies/dependencies.json') }
      status { 2 }
    end

    trait :failed do
      status { -1 }
    end
  end
end
