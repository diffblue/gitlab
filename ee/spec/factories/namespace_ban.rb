# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_ban, class: 'Namespaces::NamespaceBan' do
    namespace
    user
  end
end
