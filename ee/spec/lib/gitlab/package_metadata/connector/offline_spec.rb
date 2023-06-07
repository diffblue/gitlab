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
    let(:expected_glob) do
      if version_format == 'v2'
        "*/*.ndjson"
      else
        "*/*.csv"
      end
    end

    it "correctly lists the archive directory contents", :aggregate_failures do
      expect(Dir).to receive(:glob).with(expected_glob, base: file_prefix)
      expect(files).not_to be_empty
    end
  end

  it "processes all sequences and chunks" do
    expect(files).to match([
      have_attributes(sequence: 0, chunk: 0, purl_type: purl_type),
      have_attributes(sequence: 1, chunk: 0, purl_type: purl_type),
      have_attributes(sequence: 2, chunk: 0, purl_type: purl_type),
      have_attributes(sequence: 3, chunk: 0, purl_type: purl_type)
    ])
  end
end

RSpec.shared_examples "package metadata parser" do
  it "extracts package metadata correctly", :aggregate_failures do
    expect(files[0].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg0", "1.0.0", "BSD-3-Clause",
      purl_type))
    expect(files[1].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg1", "1.0.0", "MIT",
      purl_type))
    expect(files[2].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg2", "1.0.0", "Apache-2.0",
      purl_type))
    expect(files[3].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg3", "1.0.0", "GNU-GPLv3",
      purl_type))
  end
end

RSpec.shared_examples "compressed package metadata parser" do
  it "extracts compressed package metadata correctly", :aggregate_failures do
    expect(files[0].to_a).to contain_exactly(
      ::PackageMetadata::CompressedPackageDataObject.new(purl_type: purl_type, name: 'ai.benshi.android.sdk/core',
        default_licenses: ['Apache-2.0'], lowest_version: '0.1.0-alpha01', highest_version: '1.2.0-rc01',
        other_licenses: []))
    expect(files[1].to_a).to contain_exactly(
      ::PackageMetadata::CompressedPackageDataObject.new(purl_type: purl_type, name: 'xpp3/xpp3',
        default_licenses: ['unknown', 'Apache-1.1', 'CC-PDDC'], lowest_version: '1.1.4c', highest_version: '1.1.4c',
        other_licenses: [{ 'licenses' => ['unknown'],
                           'versions' => ['1.1.2a', '1.1.2a_min', '1.1.3.3', '1.1.3.3_min', '1.1.3.4.O', '1.1.3.4-RC3',
                             '1.1.3.4-RC8'] }]))
    expect(files[2].to_a).to contain_exactly(
      ::PackageMetadata::CompressedPackageDataObject.new(purl_type: purl_type, name: 'xml-apis/xml-apis',
        default_licenses: ['unknown'], lowest_version: '2.0.0', highest_version: '2.0.2', other_licenses:
        [{ 'licenses' => ['Apache-2.0'], 'versions' => ['1.3.04', '1.0.b2', '1.3.03'] },
          { 'licenses' => ['Apache-2.0', 'SAX-PD', 'W3C-20150513'], 'versions' => ['1.4.01'] }]))
    expect(files[3].to_a).to contain_exactly(
      ::PackageMetadata::CompressedPackageDataObject.new(purl_type: purl_type, name: 'uk.org.retep.tools.maven/script',
        default_licenses: ['0BSD', 'Apache-1.1', 'Apache-2.0', 'BSD-2-Clause', 'CC-PDDC'], lowest_version: '10.1',
        highest_version: '9.8-RC1', other_licenses: []))
  end
end

RSpec.describe ::Gitlab::PackageMetadata::Connector::Offline, feature_category: :software_composition_analysis do
  let(:archive_path) { ::PackageMetadata::SyncConfiguration.archive_path }
  let(:registry_id) { "rubygem" }
  let(:purl_type) { "gem" }
  let(:checkpoint) { nil }
  let(:connector) { described_class.new(archive_path, version_format, purl_type) }

  subject(:files) { connector.data_after(checkpoint).to_a }

  describe "#data_after" do
    context 'and version format v1' do
      let(:file_prefix) { File.join(archive_path, version_format, registry_id) }
      let(:version_format) { "v1" }

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

      context "when no checkpoint is given" do
        let(:checkpoint) { nil }

        it_behaves_like "full offline license-db sync"
        it_behaves_like "package metadata parser"
      end

      context "when a checkpoint is given" do
        context "when sequence exists and chunk do not" do
          let(:checkpoint) { build(:pm_checkpoint, sequence: 2, chunk: 3, purl_type: purl_type) }

          it_behaves_like "full offline license-db sync"
          it_behaves_like "package metadata parser"
        end

        context "when sequence and chunk do not exist" do
          let(:checkpoint) { build(:pm_checkpoint, sequence: 4, chunk: 0, purl_type: purl_type) }

          it_behaves_like "full offline license-db sync"
          it_behaves_like "package metadata parser"
        end

        context "when sequence and chunk both exist" do
          let(:checkpoint) { build(:pm_checkpoint, sequence: 2, chunk: 0, purl_type: purl_type) }

          it "processes only newer sequences and chunks" do
            expect(files).to match([
              have_attributes(sequence: 3, chunk: 0, purl_type: purl_type)
            ])
          end

          it "extracts package metadata correctly" do
            expect(files[0].to_a).to contain_exactly(::PackageMetadata::DataObject.new("pkg3", "1.0.0", "GNU-GPLv3",
              purl_type))
          end
        end
      end
    end

    context 'and version format v2' do
      let(:file_prefix) { File.join(archive_path, version_format, registry_id) }
      let(:version_format) { "v2" }

      before do
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("*/*.ndjson", base: file_prefix)
          .and_return([
            "0/0.ndjson",
            "1/0.ndjson",
            "2/0.ndjson",
            "3/0.ndjson"
          ])

        allow(File).to receive(:readlines).and_call_original
        allow(File).to receive(:readlines).with(File.absolute_path("0/0.ndjson",
          file_prefix))
          .and_return(['{"name": "ai.benshi.android.sdk/core", "lowest_version": "0.1.0-alpha01", ' \
                       '"other_licenses": [], "highest_version": "1.2.0-rc01", "default_licenses": ["Apache-2.0"]}'])
        allow(File).to receive(:readlines).with(File.absolute_path("1/0.ndjson",
          file_prefix)).and_return(['{"name": "xpp3/xpp3", "lowest_version": "1.1.4c", "other_licenses": ' \
                                    '[{"licenses": ["unknown"], "versions": ["1.1.2a", "1.1.2a_min", "1.1.3.3", ' \
                                    '"1.1.3.3_min", "1.1.3.4.O", "1.1.3.4-RC3", "1.1.3.4-RC8"]}], "highest_version": ' \
                                    '"1.1.4c", "default_licenses": ["unknown", "Apache-1.1", "CC-PDDC"]}'])
        allow(File).to receive(:readlines).with(File.absolute_path("2/0.ndjson",
          file_prefix)).and_return(['{"name": "xml-apis/xml-apis", "lowest_version": "2.0.0", "other_licenses": ' \
                                    '[{"licenses": ["Apache-2.0"], "versions": ["1.3.04", "1.0.b2", "1.3.03"]}, ' \
                                    '{"licenses": ["Apache-2.0", "SAX-PD", "W3C-20150513"], "versions": ' \
                                    '["1.4.01"]}], "highest_version": "2.0.2", "default_licenses": ["unknown"]}'])
        allow(File).to receive(:readlines).with(File.absolute_path("3/0.ndjson",
          file_prefix)).and_return(['{"name": "uk.org.retep.tools.maven/script", "lowest_version": "10.1", ' \
                                    '"other_licenses": [], "highest_version": "9.8-RC1", "default_licenses": ' \
                                    '["0BSD", "Apache-1.1", "Apache-2.0", "BSD-2-Clause", "CC-PDDC"]}'])
      end

      context "when no checkpoint is given" do
        let(:checkpoint) { nil }

        it_behaves_like "full offline license-db sync"
        it_behaves_like "compressed package metadata parser"
      end

      context "when a checkpoint is given" do
        context "when sequence exists and chunk do not" do
          let(:checkpoint) { build(:pm_checkpoint, sequence: 2, chunk: 3, purl_type: purl_type) }

          it_behaves_like "full offline license-db sync"
          it_behaves_like "compressed package metadata parser"
        end

        context "when sequence and chunk do not exist" do
          let(:checkpoint) { build(:pm_checkpoint, sequence: 4, chunk: 0, purl_type: purl_type) }

          it_behaves_like "full offline license-db sync"
          it_behaves_like "compressed package metadata parser"
        end

        context "when sequence and chunk both exist" do
          let(:checkpoint) { build(:pm_checkpoint, sequence: 2, chunk: 0, purl_type: purl_type) }

          it "processes only newer sequences and chunks" do
            expect(files).to match([
              have_attributes(sequence: 3, chunk: 0, purl_type: purl_type)
            ])
          end

          it "extracts package metadata correctly" do
            expect(files[0].to_a).to contain_exactly(::PackageMetadata::CompressedPackageDataObject.new(
              purl_type: purl_type, name: 'uk.org.retep.tools.maven/script', default_licenses: ["0BSD", "Apache-1.1",
                "Apache-2.0", "BSD-2-Clause", "CC-PDDC"], lowest_version: "10.1", highest_version: "9.8-RC1",
              other_licenses: []))
          end
        end
      end
    end
  end
end
