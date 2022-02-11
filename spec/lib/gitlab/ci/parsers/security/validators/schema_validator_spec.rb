# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Validators::SchemaValidator do
  describe 'SUPPORTED_VERSIONS' do
    let(:schema_path) { Rails.root.join("lib", "gitlab", "ci", "parsers", "security", "validators", "schemas") }
    let(:file_paths) do
      described_class::SUPPORTED_VERSIONS.flat_map do |report_type, supported_versions|
        type_name = report_type.to_s.tr("_", "-")
        file_name = "#{type_name}-report-format.json"
        supported_versions.map { |version| schema_path.join(version, file_name) }
      end
    end

    it 'has a corresponding schema on the disk' do
      existing_files = file_paths.map { |file_path| File.file?(file_path) }
      expect(existing_files).to all(be true)
    end
  end

  describe 'DEPRECATED_VERSIONS' do
    let(:schema_path) { Rails.root.join("lib", "gitlab", "ci", "parsers", "security", "validators", "schemas") }
    let(:file_paths) do
      described_class::DEPRECATED_VERSIONS.flat_map do |report_type, supported_versions|
        type_name = report_type.to_s.tr("_", "-")
        file_name = "#{type_name}-report-format.json"
        supported_versions.map { |version| schema_path.join(version, file_name) }
      end
    end

    it 'has a corresponding schema on the disk' do
      existing_files = file_paths.map { |file_path| File.file?(file_path) }
      expect(existing_files).to all(be true)
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
