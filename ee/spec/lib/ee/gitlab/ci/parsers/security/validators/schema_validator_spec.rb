# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Validators::SchemaValidator, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project) }

  let(:supported_schema_versions) { %w[15.0.0] }
  let(:validator) { described_class.new(report_type, report_data, report_data['version'], project: project) }
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

  let(:deprecated_schema_versions) { %w[14.1.0] }
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

  let(:report_type) { :dast }
  let(:valid_data) do
    {
      'version' => '15.0.0',
      'vulnerabilities' => [],
      'scan' => {
        'scanned_resources' => [],
        'type' => report_type.to_s,
        'start_time' => '2012-02-10T05:16:59',
        'end_time' => '2012-02-10T05:26:02',
        'status' => 'success',
        'analyzer' => {
          'id' => 'some-gitlab-analyzer-id',
          'name' => 'Some Analyzer',
          'version' => '0.2.0',
          'vendor' => {
            'name' => 'Some Analyzer Vendor'
          }
        },
        'scanner' => {
          'id' => 'some-gitlab-scanner-id',
          'name' => 'Some Scanner',
          'version' => '0.1.0',
          'vendor' => {
            'name' => 'Some Scanner Vendor'
          }
        }
      }
    }
  end

  let(:valid_data_for_dependency_scanning) do
    valid_data['dependency_files'] = []
    valid_data
  end

  let(:expected_missing_key_message) do
    'root is missing required keys: vulnerabilities'
  end

  let(:expected_malformed_version_message) do
    "property '/version' does not match pattern: ^[0-9]+\\.[0-9]+\\.[0-9]+$"
  end

  let(:expected_unsupported_message) do
    "Version #{report_data['version']} for report type #{report_type} is unsupported, supported versions for"\
    " this report type are: #{supported_versions}. GitLab will attempt to validate this report against the earliest"\
    " supported versions of this report type, to show all the errors but will not ingest the report"
  end

  let(:expected_error_messages) do
    [expected_missing_key_message, expected_unsupported_message, expected_malformed_version_message]
  end

  let(:expected_missing_key_message_for_dependency_scanning) do
    'root is missing required keys: dependency_files, vulnerabilities'
  end

  let(:expected_error_messages_for_dependency_scanning) do
    [expected_missing_key_message_for_dependency_scanning, expected_unsupported_message, expected_malformed_version_message]
  end

  before do
    stub_const("#{described_class}::SUPPORTED_VERSIONS", supported_hash)
    stub_const("#{described_class}::DEPRECATED_VERSIONS", deprecations_hash)
  end

  using RSpec::Parameterized::TableSyntax

  where(:report_type, :expected_errors, :report_data) do
    :cluster_image_scanning | ref(:expected_error_messages) | ref(:valid_data)
    :container_scanning | ref(:expected_error_messages) | ref(:valid_data)
    :coverage_fuzzing | ref(:expected_error_messages) | ref(:valid_data)
    :dast | ref(:expected_error_messages) | ref(:valid_data)
    :dependency_scanning | ref(:expected_error_messages_for_dependency_scanning) | ref(:valid_data_for_dependency_scanning)
    :api_fuzzing | ref(:expected_error_messages) | ref(:valid_data)
  end

  with_them do
    describe "#valid?" do
      subject { validator.valid? }

      context 'when given data is invalid according to the schema' do
        let(:report_data) { {} }

        it { is_expected.to be_falsey }
      end

      context 'when given data is valid according to the schema' do
        it { is_expected.to be_truthy }
      end
    end

    describe '#deprecation_warnings' do
      subject { validator.deprecation_warnings }

      let(:current_versions) { described_class::CURRENT_VERSIONS[report_type].join(", ") }

      context 'when report uses a deprecated version' do
        let(:deprecated_schema_version) { deprecated_schema_versions.first }
        let(:report_data) do
          valid_data['version'] = deprecated_schema_version
          valid_data
        end

        let(:expected_deprecation_message) do
          "version #{deprecated_schema_version} for report type #{report_type} is deprecated. "\
          "However, GitLab will still attempt to parse and ingest this report. "\
          "Upgrade the security report to one of the following versions: #{current_versions}."
        end

        let(:expected_deprecation_warnings) do
          [
            expected_deprecation_message
          ]
        end

        it { is_expected.to eq(expected_deprecation_warnings) }
      end

      context 'when report uses a supported version' do
        let(:supported_version) { described_class::SUPPORTED_VERSIONS[report_type].first }
        let(:report_data) { valid_data }

        it { is_expected.to eq([]) }
      end
    end

    describe '#warnings' do
      subject { validator.warnings }

      context 'when given data is valid according to the schema' do
        let(:supported_version) { described_class::SUPPORTED_VERSIONS[report_type].join(", ") }
        let(:expected_warnings) { [] }

        it { is_expected.to eq(expected_warnings) }
      end

      context 'when given data is invalid according to the schema' do
        let(:report_data) { {} }

        it { is_expected.to be_empty }
      end
    end

    describe '#errors' do
      subject { validator.errors }

      let(:report_data) do
        valid_data['version'] = "V2.1.3"
        valid_data.delete('vulnerabilities')
        valid_data
      end

      let(:supported_versions) { described_class::SUPPORTED_VERSIONS[report_type].join(", ") }

      it { is_expected.to match_array(expected_errors) }
    end
  end
end
