# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability_read, class: 'Vulnerabilities::Read' do
    vulnerability factory: :vulnerability
    project factory: :project
    scanner factory: :vulnerabilities_scanner
    report_type { :sast }
    severity { :high }
    state { :detected }
    uuid { SecureRandom.uuid }
    traits_for_enum :dismissal_reason, Vulnerabilities::DismissalReasonEnum.values.keys
  end
end
