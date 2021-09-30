# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_finding_signature, class: '::Gitlab::Ci::Reports::Security::FindingSignature' do
    algorithm_type { :hash }
    signature_value { SecureRandom.hex(50) }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::FindingSignature.new(**attributes)
    end
  end
end
