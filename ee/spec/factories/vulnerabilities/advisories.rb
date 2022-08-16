# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability_advisory, class: 'Vulnerabilities::Advisory' do
    title { FFaker::Lorem.sentence }
    affected_range { ">=5.2.0 <5.2.1.1" }
    not_impacted { FFaker::Lorem.sentence }
    component_name { FFaker::Lorem.word }
    solution { FFaker::Lorem.paragraph }
    cvss_v2 { "AV:N/AC:M/Au:N/C:N/I:P/A:N" }
    cvss_v3 { "CVSS:3.1/AV:N/AC:H/PR:L/UI:N/S:C/C:N/I:L/A:L" }
    created_date { 2.days.ago }
    published_date { 1.day.ago }
    uuid { SecureRandom.uuid }
    description { FFaker::Lorem.paragraph }
    identifiers { %w[alpha beta] }
    fixed_versions { %w[5.2.1.1] }
    urls { Array.new(2) { FFaker::Internet.uri("https") } }
    links { Array.new(2) { FFaker::Internet.uri("https") } }
  end
end
