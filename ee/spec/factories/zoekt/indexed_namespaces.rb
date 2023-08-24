# frozen_string_literal: true

FactoryBot.define do
  factory :zoekt_indexed_namespace, class: '::Zoekt::IndexedNamespace' do
    shard { association(:zoekt_shard) }
    namespace { association(:namespace) }
  end
end
