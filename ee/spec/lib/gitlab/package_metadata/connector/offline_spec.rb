# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples "full offline license-db sync" do
  using RSpec::Parameterized::TableSyntax

  # The license db does not use a directory structure
  # that maps 1:1 with the purl types. Therefore,
  # we test that we correctly convert between purl type
  # and registry id used by the license db structure.
  where(:purl_type, :registry_id) do
    :composer | "packagist"
    :conan | "conan"
    :gem | "rubygem"
    :golang | "go"
    :maven | "maven"
    :npm | "npm"
    :nuget | "nuget"
    :pypi | "pypi"
    :apk | "apk"
    :rpm | "rpm"
    :deb | "deb"
    :cbl_mariner | "cbl-mariner"
  end

  with_them do
    it "correctly lists the archive directory contents", :aggregate_failures do
      expect(Dir).to receive(:glob).with("*/*.csv", base: file_prefix)
      expect(csv_files).not_to be_empty
    end
  end

  it "processes all sequences and chunks" do
    expect(csv_files).to match([
      have_attributes(sequence: 0, chunk: 0, purl_type: purl_type),
      have_attributes(sequence: 1, chunk: 0, purl_type: purl_type),
      have_attributes(sequence: 2, chunk: 0, purl_type: purl_type),
      have_attributes(sequence: 3, chunk: 0, purl_type: purl_type)
    ])
  end

  it "extracts package metadata correctly", :aggregate_failures do
    expect(csv_files[0].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg0", "1.0.0", "BSD-3-Clause",
      purl_type))
    expect(csv_files[1].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg1", "1.0.0", "MIT",
      purl_type))
    expect(csv_files[2].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg2", "1.0.0", "Apache-2.0",
      purl_type))
    expect(csv_files[3].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg3", "1.0.0", "GNU-GPLv3",
      purl_type))
  end
end

RSpec.describe ::Gitlab::PackageMetadata::Connector::Offline, feature_category: :software_composition_analysis do
  let(:archive_path) { ::PackageMetadata::SyncConfiguration.archive_path }
  let(:file_prefix) { File.join(archive_path, version_format, registry_id) }
  let(:registry_id) { "rubygem" }
  let(:purl_type) { "gem" }
  let(:version_format) { "v1" }
  let(:checkpoint) { nil }
  let(:connector) { described_class.new(archive_path, version_format, purl_type) }

  subject(:csv_files) { connector.data_after(checkpoint).to_a }

  before do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with("*/*.csv", base: file_prefix)
      .and_return([
        "0/0.csv",
        "1/0.csv",
        "2/0.csv",
        "3/0.csv"
      ])

    allow(File).to receive(:readlines).and_call_original
    allow(File).to receive(:readlines).with(File.absolute_path("0/0.csv",
      file_prefix)).and_return(["pkg0,1.0.0,BSD-3-Clause"])
    allow(File).to receive(:readlines).with(File.absolute_path("1/0.csv",
      file_prefix)).and_return(["pkg1,1.0.0,MIT"])
    allow(File).to receive(:readlines).with(File.absolute_path("2/0.csv",
      file_prefix)).and_return(["pkg2,1.0.0,Apache-2.0"])
    allow(File).to receive(:readlines).with(File.absolute_path("3/0.csv",
      file_prefix)).and_return(["pkg3,1.0.0,GNU-GPLv3"])
  end

  describe "#data_after" do
    context "when no checkpoint is given" do
      let(:checkpoint) { nil }

      it_behaves_like "full offline license-db sync"
    end

    context "when a checkpoint is given" do
      context "when sequence exists and chunk do not" do
        let(:checkpoint) { build(:pm_checkpoint, sequence: 2, chunk: 3, purl_type: purl_type) }

        it_behaves_like "full offline license-db sync"
      end

      context "when sequence and chunk do not exist" do
        let(:checkpoint) { build(:pm_checkpoint, sequence: 4, chunk: 0, purl_type: purl_type) }

        it_behaves_like "full offline license-db sync"
      end

      context "when sequence and chunk both exist" do
        let(:checkpoint) { build(:pm_checkpoint, sequence: 2, chunk: 0, purl_type: purl_type) }

        it "processes only newer sequences and chunks" do
          expect(csv_files).to match([
            have_attributes(sequence: 3, chunk: 0, purl_type: purl_type)
          ])
        end

        it "extracts package metadata correctly" do
          expect(csv_files[0].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg3", "1.0.0", "GNU-GPLv3",
            purl_type))
        end
      end
    end
  end
end
