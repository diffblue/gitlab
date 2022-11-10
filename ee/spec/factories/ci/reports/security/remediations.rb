# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_remediation, class: '::Gitlab::Ci::Reports::Security::Remediation' do
    summary { 'Remediation summary' }
    diff { 'foo' }
    start_byte { nil }
    end_byte { nil }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Remediation.new(summary, diff, start_byte: start_byte, end_byte: end_byte)
    end
  end
end
