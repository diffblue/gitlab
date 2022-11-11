# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_merge_request_link, class: 'Vulnerabilities::MergeRequestLink' do
    vulnerability
    merge_request

    transient do
      project { nil }
    end
  end
end
