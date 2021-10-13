# frozen_string_literal: true

FactoryBot.define do
  factory :dast_profile, class: 'Dast::Profile' do
    project

    dast_site_profile { association :dast_site_profile, project: project }
    dast_scanner_profile { association :dast_scanner_profile, project: project }

    sequence :name do |i|
      "#{FFaker::Product.product_name.truncate(192)} #{SecureRandom.hex(4)} - #{i}"
    end

    description { FFaker::Product.product_name }

    trait :with_dast_site_validation do
      dast_site { association :dast_site, :with_dast_site_validation, project: project }
    end
  end
end
