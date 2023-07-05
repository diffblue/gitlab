# frozen_string_literal: true

require 'spec_helper'

require 'csv'

RSpec.describe PackageMetadata::DataObjectFabricator, feature_category: :software_composition_analysis do
  describe 'enumerable' do
    subject(:data_objects) { described_class.new(data_file: data_file, sync_config: sync_config).to_a }

    context 'when licenses' do
      let(:sync_config) do
        build(:pm_sync_config, data_type: 'licenses', purl_type: 'maven', version_format: version_format)
      end

      context 'and data_file is csv' do
        let(:version_format) { 'v1' }
        let(:io) { File.open(Rails.root.join('ee/spec/fixtures/package_metadata/sync/licenses/v1/maven.csv')) }
        let(:data_file) { Gitlab::PackageMetadata::Connector::CsvDataFile.new(io, 0, 0) }

        it {
          is_expected.to match_array([
            have_attributes(purl_type: sync_config.purl_type, name: 'ai.benshi.android.sdk/core',
              version: '0.1.0-alpha01', license: 'Apache-2.0'),
            have_attributes(purl_type: sync_config.purl_type, name: 'ai.benshi.android.sdk/core',
              version: '1.2.0-rc01', license: 'Apache-2.0'),
            have_attributes(purl_type: sync_config.purl_type, name: 'xpp3/xpp3', version: '1.1.4c', license: 'unknown'),
            have_attributes(purl_type: sync_config.purl_type, name: 'xpp3/xpp3', version: '1.1.4c',
              license: 'Apache-1.1'),
            have_attributes(purl_type: sync_config.purl_type, name: 'xpp3/xpp3', version: '1.1.4c', license: 'CC-PDDC'),
            have_attributes(purl_type: sync_config.purl_type, name: 'xml-apis/xml-apis', version: '1.3.04',
              license: 'unknown'),
            have_attributes(purl_type: sync_config.purl_type, name: 'xml-apis/xml-apis', version: '2.0.2',
              license: 'unknown'),
            have_attributes(purl_type: sync_config.purl_type, name: 'uk.org.retep.tools.maven/script', version: '10.1',
              license: '0BSD')
          ])
        }
      end

      context 'and data_file is ndjson' do
        let(:version_format) { 'v2' }
        let(:io) { File.open(Rails.root.join('ee/spec/fixtures/package_metadata/sync/licenses/v2/maven.ndjson')) }
        let(:data_file) { Gitlab::PackageMetadata::Connector::NdjsonDataFile.new(io, 0, 0) }

        it {
          is_expected.to match_array([
            have_attributes(purl_type: sync_config.purl_type, name: "ai.benshi.android.sdk/core",
              lowest_version: "0.1.0-alpha01", other_licenses: [], highest_version: "1.2.0-rc01",
              default_licenses: ["Apache-2.0"]),
            have_attributes(purl_type: sync_config.purl_type, name: "xpp3/xpp3", lowest_version: "1.1.4c",
              other_licenses: [{ "licenses" => ["unknown"], "versions" => ["1.1.2a", "1.1.2a_min", "1.1.3.3",
                "1.1.3.3_min", "1.1.3.4.O", "1.1.3.4-RC3", "1.1.3.4-RC8"] }], highest_version: "1.1.4c",
              default_licenses: ["unknown", "Apache-1.1", "CC-PDDC"]),
            have_attributes(purl_type: sync_config.purl_type, name: "xml-apis/xml-apis", lowest_version: "2.0.0",
              other_licenses: [{ "licenses" => ["Apache-2.0"], "versions" => ["1.3.04", "1.0.b2", "1.3.03"] },
                { "licenses" => ["Apache-2.0", "SAX-PD", "W3C-20150513"], "versions" => ["1.4.01"] }],
              highest_version: "2.0.2", default_licenses: ["unknown"]),
            have_attributes(purl_type: sync_config.purl_type, name: "uk.org.retep.tools.maven/script",
              lowest_version: "10.1",
              other_licenses: [], highest_version: "9.8-RC1", default_licenses: ["0BSD", "Apache-1.1", "Apache-2.0",
                "BSD-2-Clause", "CC-PDDC"])
          ])
        }
      end
    end

    context 'when advisories' do
      let(:sync_config) { build(:pm_sync_config, data_type: 'advisories', purl_type: 'maven') }
      let(:io) { File.open(Rails.root.join('ee/spec/fixtures/package_metadata/sync/advisories/v2/maven.ndjson')) }
      let(:data_file) { Gitlab::PackageMetadata::Connector::NdjsonDataFile.new(io, 0, 0) }

      subject(:data_objects) { described_class.new(data_file: data_file, sync_config: sync_config).to_a }

      it {
        is_expected.to match_array([have_attributes(advisory_xid: 'd4f176d6-0a07-46f4-9da5-22df92e5efa0',
          source_xid: 'glad', title: "Incorrect Permission Assignment for Critical Resource",
          description: "A missing permission check in Jenkins Google Kubernetes Engine Plugin allows attackers " \
                       "with Overall/Read permission to obtain limited information about the scope of a credential " \
                       "with an attacker-specified credentials ID.",
          cvss_v2: "AV:N/AC:L/Au:S/C:P/I:N/A:N",
          cvss_v3: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N",
          published_date: "2019-10-16",
          urls: ["https://nvd.nist.gov/vuln/detail/CVE-2019-10445",
            "https://jenkins.io/security/advisory/2019-10-16/#SECURITY-1607"])])
      }
    end
  end
end
