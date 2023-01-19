# frozen_string_literal: true

FactoryBot.define do
  factory :storage_limit_excluded_namespace, class: 'Namespaces::Storage::LimitExclusion' do
    namespace
    reason { 'Excluded for testing purposes' }
  end
end
