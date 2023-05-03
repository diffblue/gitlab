# frozen_string_literal: true

FactoryBot.define do
  factory :pm_advisory, class: 'PackageMetadata::Advisory' do
    advisory_xid { SecureRandom.uuid }
    source_xid { :glad }
    published_date { 1.day.ago }
    title { FFaker::Lorem.sentence }
    description { FFaker::Lorem.paragraph }
    cvss_v2 { "AV:N/AC:M/Au:N/C:N/I:P/A:N" }
    cvss_v3 { "CVSS:3.1/AV:N/AC:H/PR:L/UI:N/S:C/C:N/I:L/A:L" }
    identifiers do
      [
        { type: 'cve', name: 'CVE-2023-27797', url: 'https://nvd.nist.gov/vuln/detail/CVE-2023-22797',
          value: 'CVE-2023-27797' },
        { type: 'gemnasium', name: 'Gemnasium-0a647516-66dc-4381-9da7-601193d849e6', url: 'https://gitlab.com/gemnasium-db/package.yml',
          value: '0a647516-66dc-4381-9da7-601193d849e6' }
      ]
    end
    urls { Array.new(2) { FFaker::Internet.uri("https") } }
  end
end
