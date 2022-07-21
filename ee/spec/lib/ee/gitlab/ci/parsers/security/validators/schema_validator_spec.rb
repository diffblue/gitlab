# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Validators::SchemaValidator do
  let_it_be(:project) { create(:project) }

  using RSpec::Parameterized::TableSyntax

  where(:report_type, :expected_errors, :expected_warnings, :valid_data) do
    :cluster_image_scanning     | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :container_scanning         | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :coverage_fuzzing           | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :dast                       | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :dependency_scanning        | ['root is missing required keys: dependency_files, vulnerabilities'] | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [], 'dependency_files' => [] }
    :api_fuzzing                | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
  end

  let(:supported_schema_versions) { %w[14.1.0] }
  let(:supported_hash) do
    {
      cluster_image_scanning: supported_schema_versions,
      container_scanning: supported_schema_versions,
      coverage_fuzzing: supported_schema_versions,
      dast: supported_schema_versions,
      dependency_scanning: supported_schema_versions,
      api_fuzzing: supported_schema_versions
    }
  end

  let(:deprecated_schema_versions) { %w[10.0.0] }
  let(:deprecations_hash) do
    {
      cluster_image_scanning: deprecated_schema_versions,
      container_scanning: deprecated_schema_versions,
      coverage_fuzzing: deprecated_schema_versions,
      dast: deprecated_schema_versions,
      dependency_scanning: deprecated_schema_versions,
      api_fuzzing: deprecated_schema_versions
    }
  end

  before do
    stub_const("#{described_class}::SUPPORTED_VERSIONS", supported_hash)
    stub_const("#{described_class}::DEPRECATED_VERSIONS", deprecations_hash)
  end

  with_them do
    let(:validator) { described_class.new(report_type, report_data, valid_data['version'], project: project) }

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

    describe '#deprecation_warnings' do
      subject { validator.deprecation_warnings }

      let(:supported_versions) { described_class::SUPPORTED_VERSIONS[report_type].join(", ") }

      context 'when report uses a deprecated version' do
        let(:report_data) { valid_data }

        let(:expected_deprecation_warnings_array) do
          [
            "Version 10.0.0 for report type #{report_type} has been deprecated, supported versions for this report type are: #{supported_versions}"
          ]
        end

        it { is_expected.to eq(expected_deprecation_warnings_array) }
      end

      context 'when report uses a supported version' do
        let(:supported_version) { described_class::SUPPORTED_VERSIONS[report_type].first }
        let(:report_data) do
          valid_data['version'] = supported_version
          valid_data
        end

        it { is_expected.to eq([]) }
      end
    end

    describe '#warnings' do
      subject { validator.warnings }

      context 'when given data is valid according to the schema' do
        let(:report_data) { valid_data }
        let(:supported_version) { described_class::SUPPORTED_VERSIONS[report_type].join(", ") }
        let(:expected_warnings_array) { [] }

        it { is_expected.to eq(expected_warnings) }
      end

      context 'when given data is invalid according to the schema' do
        let(:report_data) { { 'version' => '10.0.0' } }

        it { is_expected.to be_empty }
      end
    end

    describe '#errors' do
      let(:report_data) { { 'version' => '10.0.0' } }

      subject { validator.errors }

      it { is_expected.to eq(expected_errors) }
    end
  end
end
