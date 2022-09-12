# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'rspec-parameterized'

RSpec.describe Gitlab::Vulnerabilities::Cvss::V3 do
  let(:cvss_version) { '3.1' }
  let(:attack_vector) { 'N' }
  let(:attack_complexity) { 'H' }
  let(:privileges_required) { 'N' }
  let(:user_interaction) { 'N' }
  let(:scope) { 'U' }
  let(:confidentiality) { 'H' }
  let(:integrity) { 'H' }
  let(:availability) { 'H' }

  let(:base_params) do
    {
      CVSS: cvss_version,
      AV: attack_vector,
      AC: attack_complexity,
      PR: privileges_required,
      UI: user_interaction,
      S: scope,
      C: confidentiality,
      I: integrity,
      A: availability
    }
  end

  let(:params) { base_params }

  let(:vector) do
    params.map { |key, value| "#{key}:#{value}" }.join('/')
  end

  subject(:cvss) { described_class.new(vector) }

  before do
    cvss.validate
  end

  describe 'validation for', :aggregate_failures do
    describe 'version' do
      context 'when version is valid' do
        it { is_expected.to be_valid }
      end

      context 'when version is invalid' do
        where(:cvss_version) { ['3.0', '2.0', '???', ''] }

        with_them do
          it { is_expected.to be_invalid }

          it 'reports correct error' do
            supported_versions = described_class::SUPPORTED_VERSIONS.join(', ')

            expect(cvss.errors).to match_array(
              ["version `#{cvss_version}` is not supported. Supported versions are: #{supported_versions}"])
          end
        end
      end
    end

    describe 'parameters' do
      {
        attack_vector: %w[N A L P],
        attack_complexity: %w[L H],
        privileges_required: %w[N L H],
        user_interaction: %w[N R],
        scope: %w[U C],
        confidentiality: %w[N L H],
        integrity: %w[N L H],
        availability: %w[N L H]
      }.each do |parameter, valid_parameter_values|
        context "when #{parameter} is valid" do
          where(parameter) { valid_parameter_values }

          with_them do
            it { is_expected.to be_valid }
          end
        end

        context "when #{parameter} is invalid" do
          where(parameter) { valid_parameter_values.map(&:downcase) + ['X', '?', '🦊', ''] }

          with_them do
            it { is_expected.to be_invalid }

            it 'reports correct error' do
              shortname = parameter.to_s.split('_').map { |word| word[0].upcase }.join('')

              expect(cvss.errors).to include("`#{send(parameter)}` is not a valid value for `#{shortname}`")
            end
          end
        end
      end

      context 'when a parameter is duplicated' do
        let(:vector) { "CVSS:3.1/AV:N/AV:N/AC:H/PR:L/UI:N/S:C/C:N/I:L/A:L" }

        it { is_expected.to be_invalid }

        it 'reports correct error' do
          expect(cvss.errors).to match_array(['vector contains multiple values for parameter `AV`'])
        end
      end

      context 'when parameter ordering is non-standard' do
        let(:vector) { "CVSS:3.1/A:L/I:L/C:N/S:C/AV:N/UI:N/PR:L/AC:H" }

        it { is_expected.to be_valid }
      end

      %i[AV AC PR UI S C I A].each do |parameter|
        context "when #{parameter} is missing" do
          let(:params) { base_params.except(parameter) }

          it { is_expected.to be_invalid }

          it 'reports correct error' do
            expect(cvss.errors).to match_array(["`#{parameter}` parameter is required"])
          end
        end

        context 'when version is missing' do
          let(:params) { base_params.except(:CVSS) }

          it { is_expected.to be_invalid }

          it 'reports correct error' do
            expect(cvss.errors).to include("first parameter must be `CVSS`")
          end
        end
      end

      context 'when vector contains optional metrics' do
        let(:optional_metrics) do
          {
            E: 'H',
            RL: 'U',
            RC: 'C',
            CR: 'H',
            IR: 'H',
            AR: 'H',
            MAV: 'P',
            MAC: 'H',
            MPR: 'H',
            MUI: 'R',
            MS: 'C',
            MC: 'H',
            MI: 'H',
            MA: 'H'
          }
        end

        let(:params) { base_params.merge(optional_metrics) }

        # This does not conform to the specification,
        # but advisories should only contain base metrics.
        # We will treat anything besides the base metrics as invalid
        # in order to avoid persisting invalid metrics into the DB,
        # as this could surface bugs later. For example: If we allowed
        # Exploit Code Maturity (E) to be present, but do not validate
        # the values, we might persists vectors with `E:???` which
        # could blow up later if we were to add support for the E parameter.
        it { is_expected.to be_invalid }

        it 'reports errors for each unknown metric' do
          expected_errors = optional_metrics.keys.map do |metric|
            "`#{metric}` parameter is not supported"
          end

          cvss.validate

          expect(cvss.errors).to match_array(expected_errors)
        end
      end
    end
  end
end
