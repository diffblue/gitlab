# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::MergeReportsService, :freeze_time, feature_category: :dependency_management do
  let(:uuid) { 'aec33827-20ae-40d0-ae83-18ee846364d2' }
  let(:metadata_1) { build(:ci_reports_sbom_metadata) }
  let(:metadata_2) { build(:ci_reports_sbom_metadata) }
  let(:metadata_3) { build(:ci_reports_sbom_metadata) }
  let(:licenses_1) do
    [
      { name: "MIT", spdx_identifier: "MIT" },
      { name: "BSD-3-Clause", spdx_identifier: "BSD-3-Clause" }
    ]
  end

  let(:licenses_2) do
    [
      { name: "MIT", spdx_identifier: "MIT" }
    ]
  end

  let(:licenses_3) do
    [
      { name: "BSD-3-Clause", spdx_identifier: "BSD-3-Clause" }
    ]
  end

  let(:components_1) { build_list(:ci_reports_sbom_component, 5) }
  let(:components_1_with_license) { components_1&.map { |c| to_hashie_mash(c, licenses_1) } }

  let(:components_2) { build_list(:ci_reports_sbom_component, 5) }
  let(:components_2_with_license) { components_2&.map { |c| to_hashie_mash(c, licenses_2) } }

  let(:components_3) { build_list(:ci_reports_sbom_component, 5) }
  let(:components_3_with_license) { components_3&.map { |c| to_hashie_mash(c, licenses_3) } }

  let(:components_arr_with_license) do
    Array(components_1_with_license) | Array(components_2_with_license) | Array(components_3_with_license)
  end

  let(:report_1) { build(:ci_reports_sbom_report, :with_metadata, metadata: metadata_1, components: components_1) }
  let(:report_2) { build(:ci_reports_sbom_report, :with_metadata, metadata: metadata_2, components: components_2) }
  let(:report_3) { build(:ci_reports_sbom_report, :with_metadata, metadata: metadata_3, components: components_3) }
  let(:reports) { [report_1, report_2, report_3] }

  let(:expected_report) do
    ::Gitlab::Ci::Reports::Sbom::Report.new.tap do |report|
      report.sbom_attributes = {
        bom_format: 'CycloneDX',
        spec_version: '1.4',
        serial_number: "urn:uuid:#{uuid}",
        version: 1
      }
      report.metadata = Gitlab::Ci::Reports::Sbom::Metadata.new(
        tools: Array(metadata_1&.tools) | Array(metadata_2&.tools) | Array(metadata_3&.tools),
        authors: Array(metadata_1&.authors) | Array(metadata_2&.authors) | Array(metadata_3&.authors),
        properties: Array(metadata_1&.properties) | Array(metadata_2&.properties) | Array(metadata_3&.properties)
      )
      report.components = components_arr_with_license
    end
  end

  let(:package_license_1) do
    instance_double(Gitlab::LicenseScanning::PackageLicenses, fetch: components_1_with_license)
  end

  let(:package_license_2) do
    instance_double(Gitlab::LicenseScanning::PackageLicenses, fetch: components_2_with_license)
  end

  let(:package_license_3) do
    instance_double(Gitlab::LicenseScanning::PackageLicenses, fetch: components_3_with_license)
  end

  RSpec::Matchers.define :have_json_attributes do
    match do |response|
      expect(response).to have_attributes(
        metadata: have_attributes(
          tools: expected_report.metadata.tools,
          authors: expected_report.metadata.authors,
          properties: expected_report.metadata.properties,
          timestamp: Time.current.as_json
        ),
        sbom_attributes: expected_report.sbom_attributes,
        components: expected_report.components
      )
    end
  end

  before do
    allow(Gitlab::LicenseScanning::PackageLicenses).to receive(:new).with(
      components: components_3).and_return(package_license_3)
    allow(Gitlab::LicenseScanning::PackageLicenses).to receive(:new).with(
      components: components_2).and_return(package_license_2)
    allow(Gitlab::LicenseScanning::PackageLicenses).to receive(:new).with(
      components: components_1).and_return(package_license_1)

    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  describe '#execute' do
    subject(:execute) { described_class.new(reports).execute }

    it { is_expected.to have_json_attributes }

    describe 'metadata' do
      describe 'tools' do
        context 'when tools is not present' do
          let(:metadata_1) { build(:ci_reports_sbom_metadata, tools: []) }
          let(:metadata_2) { build(:ci_reports_sbom_metadata, tools: []) }
          let(:metadata_3) { build(:ci_reports_sbom_metadata, tools: []) }

          it { is_expected.to have_json_attributes }
        end

        context 'with duplicate tools' do
          let(:tools) { [{ vendor: "vendor-1", name: "Gemnasium", version: "2.34.0" }] }
          let(:metadata_1) { build(:ci_reports_sbom_metadata, tools: tools) }
          let(:metadata_2) { build(:ci_reports_sbom_metadata, tools: tools) }
          let(:metadata_3) { build(:ci_reports_sbom_metadata, tools: tools) }

          it { is_expected.to have_json_attributes }
        end
      end

      describe 'authors' do
        context 'when authors is not present' do
          let(:metadata_1) { build(:ci_reports_sbom_metadata, authors: []) }
          let(:metadata_2) { build(:ci_reports_sbom_metadata, authors: []) }
          let(:metadata_3) { build(:ci_reports_sbom_metadata, authors: []) }

          it { is_expected.to have_json_attributes }
        end

        context 'with duplicate authors' do
          let(:authors) { [{ name: "author-1", email: "support@gitlab.com" }] }
          let(:metadata_1) { build(:ci_reports_sbom_metadata, authors: authors) }
          let(:metadata_2) { build(:ci_reports_sbom_metadata, authors: authors) }
          let(:metadata_3) { build(:ci_reports_sbom_metadata, authors: authors) }

          it { is_expected.to have_json_attributes }
        end
      end

      describe 'properties' do
        context 'when properties is not present' do
          let(:metadata_1) { build(:ci_reports_sbom_metadata, properties: []) }
          let(:metadata_2) { build(:ci_reports_sbom_metadata, properties: []) }
          let(:metadata_3) { build(:ci_reports_sbom_metadata, properties: []) }

          it { is_expected.to have_json_attributes }
        end

        context 'with duplicate properties' do
          let(:properties) { [{ name: "property-name-1", value: "package-lock.json" }] }
          let(:metadata_1) { build(:ci_reports_sbom_metadata, properties: properties) }
          let(:metadata_2) { build(:ci_reports_sbom_metadata, properties: properties) }
          let(:metadata_3) { build(:ci_reports_sbom_metadata, properties: properties) }

          it { is_expected.to have_json_attributes }
        end

        context 'with duplicate property name but different value' do
          let(:properties_1) { [{ name: "property-name-1", value: "package-lock.json" }] }
          let(:properties_2) { [{ name: "property-name-1", value: "gradle" }] }
          let(:metadata_1) { build(:ci_reports_sbom_metadata, properties: properties_1) }
          let(:metadata_2) { build(:ci_reports_sbom_metadata, properties: properties_2) }
          let(:metadata_3) { build(:ci_reports_sbom_metadata, properties: properties_1) }

          it { is_expected.to have_json_attributes }
        end
      end
    end

    describe 'components' do
      context 'when components is not present' do
        let(:components_1) { [] }
        let(:components_2) { [] }
        let(:components_3) { [] }

        it { is_expected.to have_json_attributes }
      end

      context 'with duplicate components and licenses' do
        let(:components_1) { [build(:ci_reports_sbom_component, name: "component-1")] }
        let(:components_2) { components_1 }
        let(:components_3) { components_1 }
        let(:licenses_1) { [{ name: "MIT", spdx_identifier: "MIT" }] }
        let(:licenses_2) { licenses_1 }
        let(:licenses_3) { licenses_1 }

        it { is_expected.to have_json_attributes }
      end
    end

    def to_hashie_mash(component, licenses)
      Hashie::Mash.new(name: component.name, purl: "pkg:#{component.purl_type}/#{component.name}@#{component.version}",
        version: component.version,
        type: component.component_type, purl_type: component.purl_type, licenses: licenses)
    end
  end
end
