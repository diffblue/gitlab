# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_finding_with_remediation, parent: :vulnerabilities_finding do
    transient do
      summary { nil }
    end

    after(:build) do |finding, evaluator|
      if evaluator.summary
        raw_metadata = Gitlab::Json.parse(finding.raw_metadata)
        raw_metadata.delete('solution')
        raw_metadata['remediations'] = [
          {
            summary: evaluator.summary,
            diff: Base64.encode64("This ain't a diff")
          }
        ]
        finding.raw_metadata = raw_metadata.to_json
      end
    end

    trait :yarn_remediation do
      after(:build) do |finding, evaluator|
        if evaluator.summary
          raw_metadata = Gitlab::Json.parse(finding.raw_metadata)
          raw_metadata['remediations'] = [
            {
              summary: evaluator.summary,
              diff: Base64.encode64(
                File.read(
                  File.join(
                    Rails.root.join('ee/spec/fixtures/security_reports/remediations'), "remediation.patch")
                ))
            }
          ]
          finding.raw_metadata = raw_metadata.to_json
        end
      end
    end
  end

  factory :vulnerabilities_finding, class: 'Vulnerabilities::Finding' do
    after(:build) do |finding, evaluator|
      finding.project = evaluator.vulnerability.project if evaluator.vulnerability
    end

    name { 'Cipher with no integrity' }
    project
    project_fingerprint { generate(:project_fingerprint) }
    primary_identifier factory: :vulnerabilities_identifier
    location_fingerprint { SecureRandom.hex(20) }
    report_type { :sast }
    uuid do
      Security::VulnerabilityUUID.generate(
        report_type: report_type,
        primary_identifier_fingerprint: primary_identifier.fingerprint,
        location_fingerprint: location_fingerprint,
        project_id: project_id
      )
    end
    severity { :high }
    confidence { :medium }
    detection_method { :gitlab_security_report }
    scanner factory: :vulnerabilities_scanner
    metadata_version { 'sast:1.0' }

    details do
      {
        url: {
          name: 'URL',
          type: 'url',
          href: 'http://site.com'
        }
      }
    end

    raw_metadata do
      {
        description: 'The cipher does not provide data integrity update 1',
        message: 'The cipher does not provide data integrity',
        cve: '818bf5dacb291e15d9e6dc3c5ac32178:CIPHER',
        solution: 'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
        location: {
          file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
          start_line: 29,
          end_line: 29,
          class: 'com.gitlab.security_products.tests.App',
          method: 'insecureCypher'
        },
        links: [
          {
            name: 'Cipher does not check for integrity first?',
            url: 'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first'
          }
        ],
        assets: [
          {
            type: "postman",
            name: "Test Postman Collection",
            url: "http://localhost/test.collection"
          }
        ],
        evidence: {
          summary: 'Credit card detected',
          request: {
            headers: [{ name: 'Accept', value: '*/*' }],
            method: 'GET',
            url: 'http://goat:8080/WebGoat/logout',
            body: nil
          },
          response: {
            headers: [{ name: 'Content-Length', value: '0' }],
            reason_phrase: 'OK',
            status_code: 200,
            body: nil
          },
          source: {
            id: 'assert:Response Body Analysis',
            name: 'Response Body Analysis',
            url: 'htpp://hostname/documentation'
          },
          supporting_messages: [
            {
              name: 'Origional',
              request: {
                headers: [{ name: 'Accept', value: '*/*' }],
                method: 'GET',
                url: 'http://goat:8080/WebGoat/logout',
                body: ''
              }
            },
            {
              name: 'Recorded',
              request: {
                headers: [{ name: 'Accept', value: '*/*' }],
                method: 'GET',
                url: 'http://goat:8080/WebGoat/logout',
                body: ''
              },
              response: {
                headers: [{ name: 'Content-Length', value: '0' }],
                reason_phrase: 'OK',
                status_code: 200,
                body: ''
              }
            }
          ]
        }
      }.to_json
    end

    trait :detected do
      after(:create) do |finding|
        create(:vulnerability, :detected, project: finding.project, findings: [finding])
      end
    end

    trait :confirmed do
      after(:create) do |finding|
        create(:vulnerability, :confirmed, project: finding.project, findings: [finding])
      end
    end

    trait :resolved do
      after(:create) do |finding|
        create(:vulnerability, :resolved, project: finding.project, findings: [finding])
      end
    end

    trait :dismissed do
      with_dismissal_feedback

      after(:create) do |finding|
        create(:vulnerability, :dismissed, project: finding.project, findings: [finding])
      end
    end

    trait :with_dismissal_feedback do
      after(:create) do |finding|
        create(:vulnerability_feedback, :dismissal, project: finding.project, finding_uuid: finding.uuid)
      end
    end

    trait :with_issue_feedback do
      after(:create) do |finding|
        create(
          :vulnerability_feedback,
          :issue,
          project: finding.project,
          project_fingerprint: finding.project_fingerprint
        )
      end
    end

    trait :with_secret_detection do
      after(:build) do |finding|
        finding.severity = "critical"
        finding.confidence = "unknown"
        finding.report_type = "secret_detection"
        finding.name = "AWS API key"
        finding.metadata_version = "3.0"
        finding.raw_metadata =
          { category: "secret_detection",
            name: "AWS API key",
            message: "AWS API key",
            description: "Amazon Web Services API key detected; please remove and revoke it if this is a leak.",
            cve: "aws-key.py:fac8c3618ca3c0b55431402635743c0d6884016058f696be4a567c4183c66cfd:AWS",
            severity: "Critical",
            confidence: "Unknown",
            raw_source_code_extract: "AKIAIOSFODNN7EXAMPLE",
            scanner: { id: "gitleaks", name: "Gitleaks" },
            location: { file: "aws-key.py",
                        commit: { author: "Analyzer", sha: "d874aae969588eb718e1ed18aa0be73ea69b3539" },
                        start_line: 5, end_line: 5 },
            identifiers: [{ type: "gitleaks_rule_id", name: "Gitleaks rule ID AWS", value: "AWS" }] }.to_json
      end

      after(:create) do |finding|
        create(:vulnerability, :detected, project: finding.project, findings: [finding])
      end
    end

    trait :with_secret_detection_in_no_git_mode do
      after(:build) do |finding|
        finding.severity = "critical"
        finding.confidence = "unknown"
        finding.report_type = "secret_detection"
        finding.name = "AWS API key"
        finding.metadata_version = "3.0"
        finding.raw_metadata =
          { category: "secret_detection",
            name: "AWS API key",
            message: "AWS API key",
            description: "Amazon Web Services API key detected; please remove and revoke it if this is a leak.",
            cve: "aws-key.py:fac8c3618ca3c0b55431402635743c0d6884016058f696be4a567c4183c66cfd:AWS",
            severity: "Critical",
            confidence: "Unknown",
            raw_source_code_extract: "AKIAIOSFODNN7EXAMPLE",
            scanner: { id: "gitleaks", name: "Gitleaks" },
            location: { file: "aws-key.py",
                        commit: { sha: "0000000" },
                        start_line: 5, end_line: 5 },
            identifiers: [{ type: "gitleaks_rule_id", name: "Gitleaks rule ID AWS", value: "AWS" }] }.to_json
      end

      after(:create) do |finding|
        create(:vulnerability, :detected, project: finding.project, findings: [finding])
      end
    end

    trait :with_remediation do
      after(:build) do |finding|
        raw_metadata = Gitlab::Json.parse(finding.raw_metadata)
        raw_metadata.delete(:solution)
        raw_metadata[:remediations] = [
          {
            summary: 'Use GCM mode which includes HMAC in the resulting encrypted data, providing integrity of the result.',
            diff: Base64.encode64("This is a diff")
          }
        ]
        finding.raw_metadata = raw_metadata.to_json
      end
    end

    trait :with_pipeline do
      after(:create) do |finding|
        pipeline = create(:ci_pipeline, project: finding.project)
        create(:vulnerabilities_finding_pipeline, finding: finding, pipeline: pipeline)
      end
    end

    trait :with_details do
      details do
        {
          commit: {
            name: 'The Commit',
            description: 'Commit where the vulnerability was identified',
            type: 'commit',
            value: '41df7b7eb3be2b5be2c406c2f6d28cd6631eeb19'
          },
          marked_up: {
            name: 'Marked Data',
            description: 'GFM-flavored markdown',
            type: 'markdown',
            value: "Here is markdown `inline code` #1 [test](gitlab.com)\n\n![GitLab Logo](https://about.gitlab.com/images/press/logo/preview/gitlab-logo-white-preview.png)"
          },
          diff: {
            name: 'Modified data',
            description: 'How the data was modified',
            type: 'diff',
            before: "Hello there\nHello world\nhello again",
            after: "Hello there\nHello Wooorld\nanew line\nhello again\nhello again"
          },
          table_data: {
            name: 'Registers',
            type: 'table',
            header: [
              {
                type: 'text',
                value: 'Register'
              },
              {
                type: 'text',
                value: 'Value'
              },
              {
                type: 'text',
                value: 'Note'
              }
            ],
            rows: [
              [
                {
                  type: 'text',
                  value: 'eax'
                },
                {
                  type: 'value',
                  value: 1336
                },
                {
                  type: 'text',
                  value: 'A note for eax'
                }
              ],
              [
                {
                  type: 'value',
                  value: 'ebx'
                },
                {
                  type: 'value',
                  value: 1337
                },
                {
                  type: 'value',
                  value: true
                }
              ],
              [
                {
                  type: 'text',
                  value: 'ecx'
                },
                {
                  type: 'value',
                  value: 1338
                },
                {
                  type: 'text',
                  value: 'A note for ecx'
                }
              ],
              [
                {
                  type: 'text',
                  value: 'edx'
                },
                {
                  type: 'value',
                  value: 1339
                },
                {
                  type: 'text',
                  value: 'A note for edx'
                }
              ]
            ]
          },
          urls: {
            name: 'URLs',
            description: 'The list of URLs in this report',
            type: 'list',
            items: [
              {
                type: 'url',
                href: 'https://gitlab.com'
              },
              {
                type: 'url',
                href: 'https://gitlab.com'
              },
              {
                type: 'url',
                href: 'https://gitlab.com'
              }
            ]
          },
          description: {
            name: 'Description',
            description: 'The actual description of the description',
            type: 'text',
            value: 'Text value'
          },
          code_block: {
            name: 'Code Block',
            type: 'code',
            value: "Here\nis\ncode"
          },
          named_list: {
            name: 'A Named List',
            type: 'named-list',
            items: {
              field1: {
                name: 'Field 1',
                description: 'The description for field 1',
                type: 'text',
                value: 'Text'
              },
              field2: {
                name: 'Field 2',
                description: 'The description for field 2',
                type: 'text',
                value: 'Text'
              },
              nested_ints: {
                name: 'Nested Ints',
                type: 'list',
                items: [
                  {
                    type: 'value',
                    value: 1337
                  },
                  {
                    type: 'value',
                    value: '0x1337'
                  }
                ]
              }
            }
          },
          stack_trace: {
            name: 'Stack Trace',
            type: 'list',
            items: [
              {
                type: 'module-location',
                module_name: 'compiled_binary',
                offset: 100
              },
              {
                type: 'module-location',
                module_name: 'compiled_binary',
                offset: 500
              },
              {
                type: 'module-location',
                module_name: 'compiled_binary',
                offset: 700
              },
              {
                type: 'module-location',
                module_name: 'compiled_binary',
                offset: 1000
              }
            ]
          },
          location1: {
            name: 'Location 1',
            description: 'The first location',
            type: 'file-location',
            file_name: 'new_file.c',
            line_start: 5,
            line_end: 6
          },
          module_location1: {
            name: 'Module Location 1',
            description: 'The first location',
            type: 'module-location',
            module_name: 'gitlab.h',
            offset: 100
          },
          code: {
            type: 'code',
            name: 'Truthy Code',
            value: 'function isTrue(value) { value ? true : false }',
            lang: 'javascript'
          },
          url: {
            type: 'url',
            name: 'GitLab URL',
            text: 'URL to GitLab.com',
            href: 'https://gitlab.com'
          },
          text: {
            type: 'text',
            name: 'Text with more info',
            value: 'More info about this vulnerability'
          }
        }
      end
    end

    trait :with_dependency_scanning_metadata do
      transient do
        raw_severity { "High" }
        id { "Gemnasium-06565b64-486d-4326-b906-890d9915804d" }
        file { "rails/Gemfile.lock" }
        package { "nokogiri" }
        version { "1.8.0" }
      end

      after(:build) do |finding, evaluator|
        finding.report_type = "dependency_scanning"
        finding.name = "Vulnerabilities in libxml2"
        finding.message = "Vulnerabilities in libxml2 in nokogiri"
        finding.metadata_version = "2.1"
        finding.raw_metadata = {
          "category": "dependency_scanning",
          "name": "Vulnerabilities in libxml2",
          "message": "Vulnerabilities in libxml2 in nokogiri",
          "description": "  The version of libxml2 packaged with Nokogiri contains several vulnerabilities.",
          "cve": "rails/Gemfile.lock:nokogiri:gemnasium:06565b64-486d-4326-b906-890d9915804d",
          "severity": evaluator.raw_severity,
          "solution": "Upgrade to latest version.",
          "scanner": {
            "id": "gemnasium",
            "name": "Gemnasium"
          },
          "location": {
            "file": evaluator.file,
            "dependency": {
              "package": {
                "name": evaluator.package
              },
              "version": evaluator.version
            }
          },
          "identifiers": [
            {
              "type": "gemnasium",
              "name": evaluator.id,
              "value": "06565b64-486d-4326-b906-890d9915804d",
              "url": "https://deps.sec.gitlab.com/packages/gem/nokogiri/versions/1.8.0/advisories"
            },
            {
              "type": "usn",
              "name": "USN-3424-1",
              "value": "USN-3424-1",
              "url": "https://usn.ubuntu.com/3424-1/"
            }
          ],
          "links": [
            {
              "url": "https://github.com/sparklemotion/nokogiri/issues/1673"
            }
          ]
        }.to_json
      end
    end

    trait :with_container_scanning_metadata do
      transient do
        raw_severity { "Critical" }
        id { "CVE-2021-44228" }
        image { "package-registry/package:tag" }
        package { "org.apache.logging.log4j:log4j-api" }
        version { "2.14.1" }
      end

      after(:build) do |finding, evaluator|
        finding.report_type = "container_scanning"
        finding.name = "CVE-2021-44228 in org.apache.logging.log4j:log4j-api-2.14.1"
        finding.message = "Apache Log4j2 <=2.14.1 JNDI features used in configuration, log messages, and parameters do not protect against attacker controlled LDAP and other JNDI related endpoints."
        finding.metadata_version = "2.1"
        finding.location = {
          "image": evaluator.image,
          "dependency": {
            "package": {
              "name": evaluator.package
            },
            "operating_system": "Unknown",
            "version": evaluator.version
          }
        }
        finding.raw_metadata = {
          "category": "container_scanning",
          "name": "CVE-2021-44228 in org.apache.logging.log4j:log4j-api-2.14.1",
          "message": "Apache Log4j2 <=2.14.1 JNDI features used in configuration, log messages, and parameters do not protect against attacker controlled LDAP and other JNDI related endpoints.",
          "description": "Apache Log4j2 <=2.14.1 JNDI features used in configuration, log messages, and parameters do not protect against attacker controlled LDAP and other JNDI related endpoints.",
          "severity": evaluator.raw_severity,
          "scanner": {
            "id": "trivy",
            "name": "Trivy"
          },
          "location": {
            "image": evaluator.image,
            "dependency": {
              "package": {
                "name": evaluator.package
              },
              "operating_system": "Unknown",
              "version": evaluator.version
            }
          },
          "identifiers": [
            {
              "type": "cve",
              "name": evaluator.id,
              "value": "CVE-2021-44228",
              "url": "http://packetstormsecurity.com/files/165225/Apache-Log4j2-2.14.1-Remote-Code-Execution.html"
            }
          ],
          "links": [
            {
              "url": "http://packetstormsecurity.com/files/165225/Apache-Log4j2-2.14.1-Remote-Code-Execution.html"
            }
          ]
        }.to_json
      end
    end

    trait :with_cluster_image_scanning_scanning_metadata do
      transient do
        location_image { "alpine:3.7" }
        agent_id { nil }
      end

      after(:build) do |finding, evaluator|
        finding.report_type = "cluster_image_scanning"
        finding.name = "CVE-2017-16997 in libc"
        finding.metadata_version = "2.3"
        finding.location = {
          "dependency": {
            "package": {
              "name": "glibc"
            },
            "version": "2.24-11+deb9u3"
          },
          "operating_system": "alpine 3.7",
          "image": evaluator.location_image,
          "kubernetes_resource": {
            "cluster_id": "1",
            "agent_id": evaluator.agent_id
          }
        }
        finding.raw_metadata = {
          "category": "cluster_image_scanning",
          "name": "CVE-2017-16997 in libc",
          "severity": "high",
          "solution": "Upgrade glibc from 2.24-11+deb9u3 to 2.24-11+deb9u4",
          "scanner": {
            "id": "starboard",
            "name": "Starboard"
          },
          "location": {
            "dependency": {
              "package": {
                "name": "glibc"
              },
              "version": "2.24-11+deb9u3"
            },
            "operating_system": "alpine 3.7",
            "image": "alpine:3.7",
            "kubernetes_resource": {
              "cluster_id": "1",
              "agent_id": evaluator.agent_id
            }
          },
          "identifiers": [{
            "type": "cve",
            "name": "CVE-2017-16997",
            "value": "CVE-2017-16997",
            "url": "https://security-tracker.debian.org/tracker/CVE-2017-16997"
          }],
          "links": [
            {
              "url": "https://security-tracker.debian.org/tracker/CVE-2017-16997"
            }
          ]
        }.to_json
      end
    end

    trait :identifier do
      after(:build) do |finding|
        identifier = build(
          :vulnerabilities_identifier,
          fingerprint: SecureRandom.hex(20),
          project: finding.project
        )

        finding.identifiers = [identifier]
      end
    end

    ::Enums::Vulnerability.report_types.keys.each do |security_report_type|
      trait security_report_type do
        report_type { security_report_type }
      end
    end
  end
end
