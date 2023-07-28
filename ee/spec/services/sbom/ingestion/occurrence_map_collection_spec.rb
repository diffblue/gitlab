# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::OccurrenceMapCollection, feature_category: :dependency_management do
  let(:components) do
    [
      { name: "libcom-err2", version: "1.46.2-2", type: "library",
        purl: "pkg:deb/debian/libcom-err2@1.46.2-2?distro=debian-11.4" },
      { name: "libreadline8", version: "8.1-1", type: "library",
        purl: "pkg:deb/debian/libreadline8@8.1-1?distro=debian-11.4" },
      { name: "git-man", version: "1:2.30.2-1", type: "library",
        purl: "pkg:deb/debian/git-man@1%3A2.30.2-1?distro=debian-11.4" },
      { name: "liblz4-1", version: "1.9.3-2", type: "library",
        purl: "pkg:deb/debian/liblz4-1@1.9.3-2?distro=debian-11.4" },
      { name: "readline-common", version: "8.1-1", type: "library",
        purl: "pkg:deb/debian/readline-common@8.1-1?distro=debian-11.4" },
      { name: "readline-common", version: nil, type: "library",
        purl: "pkg:deb/debian/readline-common@8.1-1?distro=debian-11.4" },
      { name: "readline-common", version: "9.1-1", type: "library",
        purl: "pkg:deb/debian/readline-common@8.1-1?distro=debian-11.4" },
      { name: "readline-common", version: "8.1-1", type: "library",
        purl: nil },
      { name: "readline-common", version: "8.1-1", type: "library",
        purl: "pkg:npm/readline-common@8.1-1" }
    ].map { |attributes| Gitlab::Ci::Reports::Sbom::Component.new(**attributes) }
  end

  let(:sbom_report) { create(:ci_reports_sbom_report, components: components) }
  let(:expected_output) do
    [
      { name: "git-man", version: "1:2.30.2-1", type: "library",
        purl: "pkg:deb/debian/git-man@1%3A2.30.2-1?distro=debian-11.4" },
      { name: "libcom-err2", version: "1.46.2-2", type: "library",
        purl: "pkg:deb/debian/libcom-err2@1.46.2-2?distro=debian-11.4" },
      { name: "liblz4-1", version: "1.9.3-2", type: "library",
        purl: "pkg:deb/debian/liblz4-1@1.9.3-2?distro=debian-11.4" },
      { name: "libreadline8", version: "8.1-1", type: "library",
        purl: "pkg:deb/debian/libreadline8@8.1-1?distro=debian-11.4" },
      { name: "readline-common", version: nil, type: "library",
        purl: "pkg:deb/debian/readline-common@8.1-1?distro=debian-11.4" },
      { name: "readline-common", version: "8.1-1", type: "library",
        purl: "pkg:deb/debian/readline-common@8.1-1?distro=debian-11.4" },
      { name: "readline-common", version: "9.1-1", type: "library",
        purl: "pkg:deb/debian/readline-common@8.1-1?distro=debian-11.4" },
      { name: "readline-common", version: "8.1-1", type: "library", purl: nil },
      { name: "readline-common", version: "8.1-1", type: "library",
        purl: "pkg:npm/readline-common@8.1-1" }
    ].map do |attributes|
      component = Gitlab::Ci::Reports::Sbom::Component.new(**attributes)
      an_occurrence_map(Sbom::Ingestion::OccurrenceMap.new(component, sbom_report.source))
    end
  end

  subject(:occurrence_map_collection) { described_class.new(sbom_report) }

  RSpec::Matchers.define :an_occurrence_map do |expected|
    attributes = %i[
      name
      version
      component_type
      purl_type
      source
    ]

    match do |actual|
      @actual = actual.to_h.slice(*attributes)
      @expected = expected.to_h.slice(*attributes)

      @actual == @expected
    end

    diffable
  end

  shared_examples '#each' do
    it 'yields for every component in consistent order when given a block' do
      expect { |b| occurrence_map_collection.each(&b) }.to yield_successive_args(*expected_output)
    end

    context 'when not given a block' do
      let(:enumerator) { occurrence_map_collection.each }

      it 'creates an occurrence map for each occurrence in consistent order' do
        expect(enumerator.to_a).to match(expected_output)
      end
    end
  end

  describe '#each' do
    it_behaves_like '#each'

    context 'when report source is nil' do
      let(:sbom_report) { create(:ci_reports_sbom_report, source: nil, components: components) }

      it_behaves_like '#each'
    end
  end
end
