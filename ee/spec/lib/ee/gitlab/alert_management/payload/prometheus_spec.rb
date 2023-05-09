# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload::Prometheus, feature_category: :incident_management do
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

    describe '#monitoring_tool' do
      subject { parsed_payload.monitoring_tool }

      it { is_expected.to eq('Prometheus') }
    end

    describe '#severity' do
      subject { parsed_payload.severity }

      it { is_expected.to eq(:low) }
    end

    describe '#environment_name' do
      subject { parsed_payload.environment_name }

      it { is_expected.to eq('production') }
    end

    describe '#gitlab_fingerprint' do
      let(:default_fingerprint) { "#{default_start_time}/default title/vector(1)" }

      subject { parsed_payload.gitlab_fingerprint }

      it { is_expected.to eq(Gitlab::AlertManagement::Fingerprint.generate(default_fingerprint)) }
    end

    describe '#source' do
      subject { parsed_payload.source }

      it { is_expected.to eq(parsed_payload.integration&.name || 'Prometheus') }
    end
  end

  describe 'attributes' do
    let_it_be(:default_start_time) { 10.days.ago.change(usec: 0).utc }
    let_it_be(:default_end_time) { 9.days.ago.change(usec: 0).utc }
    let_it_be(:mapped_start_time) { 5.days.ago.change(usec: 0).utc }
    let_it_be(:mapped_end_time) { 4.days.ago.change(usec: 0).utc }

    let(:raw_payload) do
      {
        'startsAt' => default_start_time.to_s,
        'endsAt' => default_end_time.to_s,
        'generatorURL' => 'http://localhost:9090/graph?g0.expr=vector%281%29',
        'annotations' => {
          'title' => 'default title',
          'description' => 'default description',
          'mapped_title' => 'mapped title',
          'mapped_description' => 'mapped description',
          'mapped_hosts' => ['mapped-host'],
          'mapped_fingerprint' => 'mapped fingerprint',
          'mapped_service' => 'mapped service',
          'mapped_monitoring_tool' => 'mapped monitoring tool',
          'mapped_severity' => 'high',
          'mapped_environment' => 'staging',
          'mapped_start' => mapped_start_time.to_s,
          'mapped_end' => mapped_end_time.to_s
        },
        'labels' => {
          'severity' => 'low',
          'gitlab_environment_name' => 'production'
        }
      }
    end

    context 'with multiple HTTP integrations feature available' do
      before do
        stub_licensed_features(multiple_alert_http_integrations: project)
      end

      let_it_be(:attribute_mapping) do
        {
          title: { path: %w[annotations mapped_title], type: 'string' },
          description: { path: %w[annotations mapped_description], type: 'string' },
          start_time: { path: %w[annotations mapped_start], type: 'datetime' },
          end_time: { path: %w[annotations mapped_end], type: 'datetime' },
          service: { path: %w[annotations mapped_service], type: 'string' },
          monitoring_tool: { path: %w[annotations mapped_monitoring_tool], type: 'string' },
          hosts: { path: %w[annotations mapped_hosts], type: 'string' },
          severity: { path: %w[annotations mapped_severity], type: 'string' },
          gitlab_environment_name: { path: %w[annotations mapped_environment], type: 'string' },
          fingerprint: { path: %w[annotations mapped_fingerprint], type: 'string' }
        }
      end

      let(:parsed_payload) { described_class.new(project: project, payload: raw_payload, integration: integration) }

      context 'with defined custom mapping' do
        let_it_be(:integration) do
          create(
            :alert_management_prometheus_integration,
            project: project,
            payload_attribute_mapping: attribute_mapping
          )
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

          it { is_expected.to eq('staging') }
        end

        describe '#gitlab_fingerprint' do
          subject { parsed_payload.gitlab_fingerprint }

          it { is_expected.to eq(Gitlab::AlertManagement::Fingerprint.generate('mapped fingerprint')) }
        end

        describe '#source' do
          subject { parsed_payload.source }

          it { is_expected.to eq('mapped monitoring tool') }
        end
      end

      context 'with only some attributes defined in custom mapping' do
        let_it_be(:attribute_mapping) do
          {
            title: { path: %w[annotations mapped_title], type: 'string' }
          }
        end

        let_it_be(:integration) do
          create(
            :alert_management_prometheus_integration,
            project: project,
            payload_attribute_mapping: attribute_mapping
          )
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

      context 'when the payload has is missing default attributes' do
        let(:raw_payload) do
          {
            'annotations' => {
              'mapped_title' => 'mapped title',
              'mapped_description' => 'mapped description'
            }
          }
        end

        let_it_be(:attribute_mapping) do
          {
            title: { path: %w[annotations mapped_title], type: 'string' },
            description: { path: %w[annotations mapped_description], type: 'string' }
          }
        end

        let_it_be(:integration) do
          create(
            :alert_management_prometheus_integration,
            project: project,
            payload_attribute_mapping: attribute_mapping
          )
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
          create(
            :alert_management_prometheus_integration,
            :inactive,
            project: project,
            payload_attribute_mapping: attribute_mapping
          )
        end

        it_behaves_like 'parsing alert payload fields with default paths'
      end

      context 'with blank custom mapping' do
        let_it_be(:integration) { create(:alert_management_prometheus_integration, project: project) }

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
end
