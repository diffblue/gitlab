# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::ExportSerializers::JsonService, feature_category: :dependency_management do
  let(:uuid) { 'aec33827-20ae-40d0-ae83-18ee846364d2' }
  let(:components) do
    [
      Hashie::Mash.new(
        name: "com.fasterxml.jackson.core/jackson-annotations",
        purl: "pkg:maven/com.fasterxml.jackson.core/jackson-annotations@2.9.0",
        version: "2.9.0",
        type: "library",
        purl_type: "maven",
        licenses: [
          { name: "MIT", spdx_identifier: "MIT" }
        ]
      ),
      Hashie::Mash.new(
        name: "com.fasterxml.jackson.core/jackson-core",
        purl: "pkg:maven/com.fasterxml.jackson.core/jackson-core@2.9.2",
        version: "2.9.2",
        type: "library",
        purl_type: "maven",
        licenses: [
          { name: "MIT", spdx_identifier: "MIT" },
          { name: "BSD 3-Clause", spdx_identifier: "BSD-3-Clause" }
        ]
      ),
      Hashie::Mash.new(
        name: "com.fasterxml.jackson.core/jackson-invalid",
        purl: "pkg:maven/com.fasterxml.jackson.core/jackson-invalid@2.9.0",
        version: "2.9.0",
        type: "library",
        purl_type: "maven",
        licenses: [
          { name: "unknown" }
        ]
      )
    ]
  end

  let(:json_file_path) { 'ee/spec/fixtures/sbom/gl-sbom-maven-maven.cdx.json' }
  let(:json_file) { JSON.load_file(json_file_path) }
  let(:service) { described_class.new(report) }

  let(:metadata) do
    metadata = ::Gitlab::Ci::Reports::Sbom::Metadata.new(
      tools: [{ name: "Gemnasium", vendor: "Gitlab", version: "2.34.0" }],
      authors: [{ email: "support@gitlab.com", name: "Gitlab" }],
      properties: [{ name: "gitlab:dependency_scanning:input_file", value: "package-lock.json" }]
    )
    metadata.timestamp = "2020-04-13T20:20:39+00:00"
    metadata
  end

  let(:report) do
    report = ::Gitlab::Ci::Reports::Sbom::Report.new
    report.sbom_attributes = {
      bom_format: 'CycloneDX',
      spec_version: '1.4',
      serial_number: "urn:uuid:#{uuid}",
      version: 1
    }
    report.metadata = metadata
    report.components = components
    report
  end

  describe '#execute' do
    subject(:sbom_json) { service.execute }

    context 'with valid report' do
      it 'generates a valid cyclonedx json file' do
        expect(sbom_json).not_to be_nil
        expect(sbom_json.as_json.with_indifferent_access).to eq json_file
        expect(service.errors).to be_empty
        expect(service.valid?).to be_truthy
      end
    end

    context 'with invalid report' do
      let(:report) do
        report = ::Gitlab::Ci::Reports::Sbom::Report.new
        report.sbom_attributes = { invalid: 'json' }
        report
      end

      it 'returns nil and sets errors' do
        expect(sbom_json).to be_nil
        expect(service.errors).not_to be_empty
        expect(service.valid?).to be_falsey
      end
    end
  end
end
