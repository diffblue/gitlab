# frozen_string_literal: true

FactoryBot.define do
  factory :spdx_license, class: '::Gitlab::SPDX::License' do
    id { |n| "License-#{n}" }
    name { |n| "License #{n}" }
    deprecated { false }

    trait :apache_1 do
      id { 'Apache-1.0' }
      name { 'Apache License 1.0' }
    end

    trait :bsd do
      id { 'BSD-4-Clause' }
      name { 'BSD 4-Clause "Original" or "Old" License' }
    end

    trait :mit do
      id { 'MIT' }
      name { 'MIT License' }
    end

    trait :deprecated_gpl_v1 do
      id { 'GPL-1.0' }
      name { 'GNU General Public License v1.0 only' }
      deprecated { true }
    end

    trait :gpl_v1 do
      id { 'GPL-1.0-only' }
      name { 'GNU General Public License v1.0 only' }
    end

    skip_create
  end
end
