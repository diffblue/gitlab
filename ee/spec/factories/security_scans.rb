# frozen_string_literal: true

FactoryBot.define do
  factory :security_scan, class: 'Security::Scan' do
    scan_type { 'dast' }
    build factory: [:ci_build, :success]
  end
end
