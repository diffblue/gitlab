# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_finding_signature, class: 'Vulnerabilities::FindingSignature' do
    finding factory: :vulnerabilities_finding
    algorithm_type { ::Vulnerabilities::FindingSignature.algorithm_types[:hash] }
    signature_sha { ::Digest::SHA1.digest(SecureRandom.hex(50)) }

    trait :location do
      algorithm_type { :location }
    end
  end
end
