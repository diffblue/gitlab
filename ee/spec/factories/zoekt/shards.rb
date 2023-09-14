# frozen_string_literal: true

FactoryBot.define do
  factory :zoekt_shard, class: '::Zoekt::Shard' do
    index_base_url { 'http://111.111.111.111/' }
    search_base_url { 'http://111.111.111.112/' }
  end
end
