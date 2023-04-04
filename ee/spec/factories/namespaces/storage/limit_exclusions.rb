# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_storage_limit_exclusion, class: 'Namespaces::Storage::LimitExclusion' do
    namespace
    reason { 'Excluded for testing purposes' }
  end
end
