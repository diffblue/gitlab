# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::AdvisoryDataObject, feature_category: :software_composition_analysis do
  describe '.create' do
    let(:purl_type) { 'npm' }
    let(:hash) do
      {
        "advisory" =>
          {
            "id" => "d4f176d6-0a07-46f4-9da5-22df92e5efa0",
            "source" => "glad",
            "title" => "Incorrect Permission Assignment for Critical Resource",
            "description" => "A missing permission check in Jenkins Google Kubernetes Engine Plugin allows attackers " \
                             "with Overall/Read permission to obtain limited information about the scope of a " \
                             "credential with an attacker-specified credentials ID.",
            "cvss_v2" => "AV:N/AC:L/Au:S/C:P/I:N/A:N",
            "cvss_v3" => "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N",
            "published_date" => "2019-10-16",
            "urls" => ["https://nvd.nist.gov/vuln/detail/CVE-2019-10445",
              "https://jenkins.io/security/advisory/2019-10-16/#SECURITY-1607"],
            "identifiers" =>
              [
                { "type" => "cve", "name" => "CVE-2019-10445", "value" => "CVE-2019-10445",
                  "url" => "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-10445" },
                { "type" => "cwe", "name" => "CWE-1035", "value" => "1035",
                  "url" => "https://cwe.mitre.org/data/definitions/1035.html" },
                { "type" => "cwe", "name" => "CWE-862", "value" => "862",
                  "url" => "https://cwe.mitre.org/data/definitions/862.html" },
                { "type" => "cwe", "name" => "CWE-937", "value" => "937",
                  "url" => "https://cwe.mitre.org/data/definitions/937.html" }
              ]
          },
        "packages" => [
          {
            "name" => "org.jenkins-ci.plugins/google-kubernetes-engine",
            "affected_range" => "(,0.7.0]",
            "solution" => "Upgrade to version 0.8 or above.",
            "fixed_versions" => ["0.8"]
          }
        ]
      }
    end

    subject(:create) { described_class.create(hash, purl_type) }

    it { is_expected.to be_kind_of(described_class) }

    it {
      is_expected.to match(have_attributes(advisory_xid: 'd4f176d6-0a07-46f4-9da5-22df92e5efa0', source_xid: 'glad',
        title: "Incorrect Permission Assignment for Critical Resource",
        description: "A missing permission check in Jenkins Google Kubernetes Engine Plugin allows attackers with " \
                     "Overall/Read permission to obtain limited information about the scope of a credential with an " \
                     "attacker-specified credentials ID.",
        cvss_v2: "AV:N/AC:L/Au:S/C:P/I:N/A:N",
        cvss_v3: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N",
        published_date: "2019-10-16",
        urls: ["https://nvd.nist.gov/vuln/detail/CVE-2019-10445",
          "https://jenkins.io/security/advisory/2019-10-16/#SECURITY-1607"],
        identifiers: [
          { type: "cve", name: "CVE-2019-10445", value: "CVE-2019-10445",
            url: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-10445" },
          { type: "cwe", name: "CWE-1035", value: "1035", url: "https://cwe.mitre.org/data/definitions/1035.html" },
          { type: "cwe", name: "CWE-862", value: "862", url: "https://cwe.mitre.org/data/definitions/862.html" },
          { type: "cwe", name: "CWE-937", value: "937", url: "https://cwe.mitre.org/data/definitions/937.html" }
        ],
        affected_packages: [
          have_attributes(purl_type: purl_type,
            package_name: 'org.jenkins-ci.plugins/google-kubernetes-engine', affected_range: '(,0.7.0]',
            solution: 'Upgrade to version 0.8 or above.', fixed_versions: ["0.8"])
        ]))
    }

    context 'when an attribute is missing' do
      using RSpec::Parameterized::TableSyntax
      subject(:create!) do
        described_class.create({ 'advisory' => hash['advisory'].except(attribute.to_s),
          'packages' => hash['packages'] }, purl_type)
      end

      context 'and it is on the advisory hash' do
        where(:attribute, :required) do
          :title | false
          :description  | false
          :cvvs_v2      | false
          :cvvs_v3      | false
          :urls         | false
          :identifiers  | false
          :id           | true
          :source       | true
        end

        with_them do
          specify do
            required ? expect { create! }.to(raise_error(ArgumentError)) : expect { create! }.not_to(raise_error)
          end
        end
      end

      context 'and it is packages' do
        subject(:create!) { described_class.create(hash.except('packages'), purl_type) }

        specify { expect { create! }.to raise_error(ArgumentError) }
      end
    end
  end
end
