# frozen_string_literal: true

FactoryBot.define do
  factory :finding_map, class: '::Security::Ingestion::FindingMap' do
    security_finding
    report_finding factory: :ci_reports_security_finding

    trait :with_finding do
      finding factory: :vulnerabilities_finding
    end

    trait :new_record do
      with_finding

      new_record { true }
      vulnerability factory: :vulnerability
    end

    initialize_with do
      ::Security::Ingestion::FindingMap.new(*attributes.values_at(:security_finding, :report_finding)).tap do |object|
        object.finding_id = attributes[:finding]&.id
        object.vulnerability_id = attributes[:vulnerability]&.id
        object.new_record = attributes[:new_record]
        object.identifier_ids = attributes[:identifier_ids].to_a
      end
    end

    skip_create
  end
end
