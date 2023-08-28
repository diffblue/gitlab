# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::SbomEntity, feature_category: :dependency_management do
  let(:metadata) { build(:ci_reports_sbom_metadata) }
  let(:components) { build_list(:ci_reports_sbom_component, 5).map { |c| to_hashie_mash(c, licenses) } }
  let(:report) { build(:ci_reports_sbom_report, :with_metadata, metadata: metadata, components: components) }
  let(:reports) { [report] }
  let(:licenses) do
    [
      { name: "MIT", spdx_identifier: "MIT" },
      { name: "BSD-3-Clause", spdx_identifier: "BSD-3-Clause" }
    ]
  end

  subject { described_class.new(report).as_json }

  it 'has sbom attributes' do
    expect(subject).to include(:bomFormat, :specVersion, :serialNumber, :version, :metadata)
  end

  it 'has sbom components attributes' do
    expect(subject[:components].first.keys.sort).to include(:name, :purl, :type, :version)
  end

  context 'with a known license type' do
    let(:licenses) do
      [
        { name: "MIT", spdx_identifier: "MIT" },
        { name: "BSD-3-Clause", spdx_identifier: "BSD-3-Clause" }
      ]
    end

    it 'has sbom licenses attributes' do
      expect(subject[:components].first.keys.sort).to include(:licenses, :name, :purl, :type, :version)
      expect(subject[:components].first[:licenses]).to eq(
        [
          { license: { id: "MIT", url: "https://spdx.org/licenses/MIT.html" } },
          { license: { id: "BSD-3-Clause", url: "https://spdx.org/licenses/BSD-3-Clause.html" } }
        ]
      )
    end
  end

  context 'with an unknown license type' do
    let(:licenses) do
      [
        { name: "unknown", spdx_identifier: "unknown" },
        { name: "BSD-3-Clause", spdx_identifier: "BSD-3-Clause" }
      ]
    end

    it 'has sbom licenses attributes' do
      expect(subject[:components].first.keys.sort).to include(:licenses, :name, :purl, :type, :version)
      expect(subject[:components].first[:licenses]).to eq(
        [
          { license: { name: "unknown" } },
          { license: { id: "BSD-3-Clause", url: "https://spdx.org/licenses/BSD-3-Clause.html" } }
        ]
      )
    end
  end

  def to_hashie_mash(component, licenses)
    Hashie::Mash.new(name: component.name, purl: "pkg:#{component.purl_type}/#{component.name}@#{component.version}",
      version: component.version, type: component.component_type, purl_type: component.purl_type,
      licenses: licenses
    )
  end
end
