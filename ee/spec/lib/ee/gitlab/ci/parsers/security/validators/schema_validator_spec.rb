# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Validators::SchemaValidator do
  using RSpec::Parameterized::TableSyntax

  where(:report_type, :expected_errors, :expected_warnings, :valid_data) do
    :cluster_image_scanning     | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :container_scanning         | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :coverage_fuzzing           | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :dast                       | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
    :dependency_scanning        | ['root is missing required keys: dependency_files, vulnerabilities'] | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [], 'dependency_files' => [] }
    :api_fuzzing                | ['root is missing required keys: vulnerabilities']                   | lazy { expected_warnings_array } | { 'version' => '10.0.0', 'vulnerabilities' => [] }
  end

  with_them do
    let(:validator) { described_class.new(report_type, report_data, valid_data['version']) }

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

    describe '#warnings' do
      subject { validator.warnings }

      context 'when given data is valid according to the schema' do
        let(:report_data) { valid_data }
        let(:supported_version) { described_class::SUPPORTED_VERSIONS[report_type].join(", ") }
        let(:expected_warnings_array) do
          [
            "Version 10.0.0 for report type #{report_type} has been deprecated, supported versions for this report type are: #{supported_version}"
          ]
        end

        it { is_expected.to eq(expected_warnings) }
      end
    end

    describe '#errors' do
      let(:report_data) { { 'version' => '10.0.0' } }

      subject { validator.errors }

      it { is_expected.to eq(expected_errors) }
    end
  end
end
