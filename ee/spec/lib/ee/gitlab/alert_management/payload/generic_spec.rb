# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload::Generic do
  let_it_be(:project) { create(:project) }

  let(:raw_payload) { {} }
  let(:parsed_payload) { described_class.new(project: project, payload: raw_payload) }

  shared_examples 'parsing alert payload fields with default paths' do
    describe '#title' do
      subject { parsed_payload.title }

      it { is_expected.to eq('default title') }
    end

    describe '#description' do
      subject { parsed_payload.description }

      it { is_expected.to eq('default description') }
    end

    describe '#starts_at' do
      subject { parsed_payload.starts_at }

      it { is_expected.to eq(default_start_time) }
    end

    describe '#ends_at' do
      subject { parsed_payload.ends_at }

      it { is_expected.to eq(default_end_time) }
    end

    describe '#service' do
      subject { parsed_payload.service }

      it { is_expected.to eq('default service') }
    end

    describe '#monitoring_tool' do
      subject { parsed_payload.monitoring_tool }

      it { is_expected.to eq('default monitoring tool') }
    end

    describe '#host' do
      subject { parsed_payload.hosts }

      it { is_expected.to eq(['default-host']) }
    end

    describe '#severity' do
      subject { parsed_payload.severity }

      it { is_expected.to eq(:low) }
    end

    describe '#environment_name' do
      subject { parsed_payload.environment_name }

      it { is_expected.to eq('default gitlab environment') }
    end

    describe '#gitlab_fingerprint' do
      subject { parsed_payload.gitlab_fingerprint }

      it { is_expected.to eq(Gitlab::AlertManagement::Fingerprint.generate('default fingerprint')) }
    end
  end

  describe 'attributes' do
    let_it_be(:default_start_time) { 10.days.ago.change(usec: 0).utc }
    let_it_be(:default_end_time) { 9.days.ago.change(usec: 0).utc }
    let_it_be(:mapped_start_time) { 5.days.ago.change(usec: 0).utc }
    let_it_be(:mapped_end_time) { 4.days.ago.change(usec: 0).utc }
    let_it_be(:raw_payload) do
      {
        'title' => 'default title',
        'description' => 'default description',
        'start_time' => default_start_time.to_s,
        'end_time' => default_end_time.to_s,
        'service' => 'default service',
        'monitoring_tool' => 'default monitoring tool',
        'hosts' => ['default-host'],
        'severity' => 'low',
        'gitlab_environment_name' => 'default gitlab environment',
        'fingerprint' => 'default fingerprint',
        'alert' => {
          'name' => 'mapped title',
          'desc' => 'mapped description',
          'start_time' => mapped_start_time.to_s,
          'end_time' => mapped_end_time.to_s,
          'service' => 'mapped service',
          'monitoring_tool' => 'mapped monitoring tool',
          'hosts' => ['mapped-host'],
          'severity' => 'high',
          'env_name' => 'mapped gitlab environment',
          'fingerprint' => 'mapped fingerprint'
        }
      }
    end

    context 'with multiple HTTP integrations feature available' do
      before do
        stub_licensed_features(multiple_alert_http_integrations: project)
      end

      let_it_be(:attribute_mapping) do
        {
          title: { path: %w(alert name), type: 'string' },
          description: { path: %w(alert desc), type: 'string' },
          start_time: { path: %w(alert start_time), type: 'datetime' },
          end_time: { path: %w(alert end_time), type: 'datetime' },
          service: { path: %w(alert service), type: 'string' },
          monitoring_tool: { path: %w(alert monitoring_tool), type: 'string' },
          hosts: { path: %w(alert hosts), type: 'string' },
          severity: { path: %w(alert severity), type: 'string' },
          gitlab_environment_name: { path: %w(alert env_name), type: 'string' },
          fingerprint: { path: %w(alert fingerprint), type: 'string' }
        }
      end

      let(:parsed_payload) { described_class.new(project: project, payload: raw_payload, integration: integration) }

      context 'with defined custom mapping' do
        let_it_be(:integration) do
          create(:alert_management_http_integration, project: project, payload_attribute_mapping: attribute_mapping)
        end

        describe '#title' do
          subject { parsed_payload.title }

          it { is_expected.to eq('mapped title') }
        end

        describe '#description' do
          subject { parsed_payload.description }

          it { is_expected.to eq('mapped description') }
        end

        describe '#starts_at' do
          subject { parsed_payload.starts_at }

          it { is_expected.to eq(mapped_start_time) }
        end

        describe '#ends_at' do
          subject { parsed_payload.ends_at }

          it { is_expected.to eq(mapped_end_time) }
        end

        describe '#service' do
          subject { parsed_payload.service }

          it { is_expected.to eq('mapped service') }
        end

        describe '#monitoring_tool' do
          subject { parsed_payload.monitoring_tool }

          it { is_expected.to eq('mapped monitoring tool') }
        end

        describe '#host' do
          subject { parsed_payload.hosts }

          it { is_expected.to eq(['mapped-host']) }
        end

        describe '#severity' do
          subject { parsed_payload.severity }

          it { is_expected.to eq(:high) }
        end

        describe '#environment_name' do
          subject { parsed_payload.environment_name }

          it { is_expected.to eq('mapped gitlab environment') }
        end

        describe '#gitlab_fingerprint' do
          subject { parsed_payload.gitlab_fingerprint }

          it { is_expected.to eq(Gitlab::AlertManagement::Fingerprint.generate('mapped fingerprint')) }
        end
      end

      context 'with only some attributes defined in custom mapping' do
        let_it_be(:attribute_mapping) do
          {
            title: { path: %w(alert name), type: 'string' }
          }
        end

        let_it_be(:integration) do
          create(:alert_management_http_integration, project: project, payload_attribute_mapping: attribute_mapping)
        end

        describe '#title' do
          subject { parsed_payload.title }

          it 'uses the value defined by the custom mapping' do
            is_expected.to eq('mapped title')
          end
        end

        describe '#description' do
          subject { parsed_payload.description }

          it 'falls back to the default value' do
            is_expected.to eq('default description')
          end
        end
      end

      context 'when the payload has no default generic attributes' do
        let_it_be(:raw_payload) do
          {
            'alert' => {
              'name' => 'mapped title',
              'desc' => 'mapped description'
            }
          }
        end

        let_it_be(:attribute_mapping) do
          {
            title: { path: %w(alert name), type: 'string' },
            description: { path: %w(alert desc), type: 'string' }
          }
        end

        let_it_be(:integration) do
          create(:alert_management_http_integration, project: project, payload_attribute_mapping: attribute_mapping)
        end

        describe '#title' do
          subject { parsed_payload.title }

          it { is_expected.to eq('mapped title') }
        end

        describe '#description' do
          subject { parsed_payload.description }

          it { is_expected.to eq('mapped description') }
        end
      end

      context 'with inactive HTTP integration' do
        let_it_be(:integration) do
          create(:alert_management_http_integration, :inactive, project: project, payload_attribute_mapping: attribute_mapping)
        end

        it_behaves_like 'parsing alert payload fields with default paths'
      end

      context 'with blank custom mapping' do
        let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

        it_behaves_like 'parsing alert payload fields with default paths'
      end
    end

    context 'with multiple HTTP integrations feature unavailable' do
      before do
        stub_licensed_features(multiple_alert_http_integrations: false)
      end

      it_behaves_like 'parsing alert payload fields with default paths'
    end
  end

  describe '#gitlab_fingerprint' do
    subject { parsed_payload.gitlab_fingerprint }

    context 'with fingerprint defined in payload' do
      let(:expected_fingerprint) { Digest::SHA1.hexdigest(plain_fingerprint) }
      let(:plain_fingerprint) { 'fingerprint' }
      let(:raw_payload) { { 'fingerprint' => plain_fingerprint } }

      it { is_expected.to eq(expected_fingerprint) }
    end

    context 'license feature enabled' do
      let(:expected_fingerprint) { Gitlab::AlertManagement::Fingerprint.generate(plain_fingerprint) }
      let(:plain_fingerprint) { raw_payload.except('hosts', 'start_time') }
      let(:raw_payload) do
        {
          'keep-this' => 'attribute',
          'hosts' => 'remove me',
          'start_time' => 'remove me'
        }
      end

      before do
        stub_licensed_features(generic_alert_fingerprinting: true)
      end

      it { is_expected.to eq(expected_fingerprint) }

      context 'payload has no values' do
        let(:raw_payload) do
          {
            'start_time' => '2020-09-17 12:49:54 -0400',
            'hosts' => ['gitlab.com'],
            'end_time' => '2020-09-17 12:59:54 -0400',
            'title' => ' '
          }
        end

        it { is_expected.to be_nil }
      end
    end

    context 'license feature not enabled' do
      it { is_expected.to be_nil }
    end
  end
end
