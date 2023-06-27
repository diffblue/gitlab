# frozen_string_literal: true

require 'spec_helper'

require 'csv'

RSpec.describe PackageMetadata::DataObjectFabricator, feature_category: :software_composition_analysis do
  subject(:produced) { described_class.new(data_file: data_file, sync_config: sync_config).to_a }

  describe 'enumerable' do
    context 'when licenses' do
      let(:sync_config) { build(:pm_sync_config, purl_type: 'maven', version_format: version_format) }

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
  end
end
