# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability_read, class: 'Vulnerabilities::Read' do
    vulnerability factory: :vulnerability
    project factory: :project
    scanner factory: :vulnerabilities_scanner
    report_type { :sast }
    severity { :high }
    state { Vulnerability.states[:detected] }
    uuid { SecureRandom.uuid }
  end
end
