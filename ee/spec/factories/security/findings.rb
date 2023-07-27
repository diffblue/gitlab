# frozen_string_literal: true

FactoryBot.define do
  factory :security_finding, class: 'Security::Finding' do
    scanner factory: :vulnerabilities_scanner
    scan factory: :security_scan

    severity { :critical }
    confidence { :high }
    uuid { SecureRandom.uuid }
    project_fingerprint { generate(:project_fingerprint) }

    transient do
      false_positive { false }
    end

    transient do
      remediation_byte_offsets { [{ "end_byte" => 13602, "start_byte" => 12719 }] }
    end

    trait :with_finding_data do
      finding_data do
        {
          name: 'Test finding',
          description: 'The cipher does not provide data integrity update 1',
          solution: 'foo',
          identifiers: [],
          links: [
            {
              name: 'Cipher does not check for integrity first?',
              url: 'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first'
            }
          ],
          false_positive?: false_positive,
          location: {},
          evidence: {},
          assets: [],
          details: {},
          raw_source_code_extract: 'AES/ECB/NoPadding',
          remediation_byte_offsets: remediation_byte_offsets
        }
      end
    end
  end
end
