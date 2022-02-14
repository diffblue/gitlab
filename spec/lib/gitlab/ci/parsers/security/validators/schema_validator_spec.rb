# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Validators::SchemaValidator do
  describe 'SUPPORTED_VERSIONS' do
    # This is not a stub, let is not accessible within context blocks
    # rubocop:disable RSpec/LeakyConstantDeclaration
    SCHEMA_PATH = Rails.root.join("lib", "gitlab", "ci", "parsers", "security", "validators", "schemas")
    # rubocop:enable RSpec/LeakyConstantDeclaration

    it 'matches DEPRECATED_VERSIONS keys' do
      expect(described_class::SUPPORTED_VERSIONS.keys).to eq(described_class::DEPRECATED_VERSIONS.keys)
    end

    context 'files under SCHEMA_PATH are explicitly listed' do
      # We only care about the part that comes before report-format.json
      # https://rubular.com/r/N8Juz7r8hYDYgD
      filename_regex = /(?<report_type>[-\w]*)\-report-format.json/

      versions = Dir.glob(File.join(SCHEMA_PATH, "*", File::SEPARATOR)).map { |path| path.split("/").last }

      versions.each do |version|
        files = Dir[SCHEMA_PATH.join(version, "*.json")]

        files.each do |file|
          matches = filename_regex.match(file)
          report_type = matches[:report_type].tr("-", "_").to_sym

          it "#{report_type} #{version}" do
            expect(described_class::SUPPORTED_VERSIONS[report_type]).to include(version)
          end
        end
      end
    end

    context 'every SUPPORTED_VERSION has a corresponding JSON file' do
      described_class::SUPPORTED_VERSIONS.each_key do |report_type|
        let(:filename) { "#{report_type.to_s.tr("_", "-")}-report-format.json" }

        described_class::SUPPORTED_VERSIONS[report_type].each do |version|
          it "#{report_type} #{version} schema file is present" do
            full_path = SCHEMA_PATH.join(version, filename)
            expect(File.file?(full_path)).to be true
          end
        end
      end
    end
  end

  describe 'DEPRECATED_VERSIONS' do
    it 'matches SUPPORTED_VERSIONS keys' do
      expect(described_class::DEPRECATED_VERSIONS.keys).to eq(described_class::SUPPORTED_VERSIONS.keys)
    end
  end

  using RSpec::Parameterized::TableSyntax

  where(:report_type, :expected_errors, :valid_data) do
    'sast' | ['root is missing required keys: vulnerabilities'] | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :sast  | ['root is missing required keys: vulnerabilities'] | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :secret_detection | ['root is missing required keys: vulnerabilities'] | { 'version' => '10.0.0', 'vulnerabilities' => [] }
  end

  with_them do
    let(:validator) { described_class.new(report_type, report_data) }

    describe '#valid?' do
      subject { validator.valid? }

      context 'when given data is invalid according to the schema' do
        let(:report_data) { {} }

        it { is_expected.to be_falsey }
      end

      context 'when given data is valid according to the schema' do
        let(:report_data) { valid_data }

        it { is_expected.to be_truthy }
      end
    end

    describe '#errors' do
      let(:report_data) { { 'version' => '10.0.0' } }

      subject { validator.errors }

      it { is_expected.to eq(expected_errors) }
    end
  end
end
