# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::ProjectCiCdSettingsUpdate, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  subject { mutation.resolve(full_path: project.full_path, **mutation_params) }

  before do
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    stub_feature_flags(disable_merge_trains: false)
    project.merge_pipelines_enabled = nil
    project.merge_trains_enabled = false
  end

  describe '#resolve' do
    before do
      subject
      project.reload
    end

    context 'when merge trains are set to true and merge pipelines are set to false' do
      let(:mutation_params) do
        {
          full_path: project.full_path,
          merge_pipelines_enabled: false,
          merge_trains_enabled: true
        }
      end

      it 'does not enable merge trains' do
        expect(project.ci_cd_settings.merge_trains_enabled?).to eq(false)
      end
    end

    context 'when merge trains and merge pipelines are set to true' do
      let(:mutation_params) do
        {
          full_path: project.full_path,
          merge_pipelines_enabled: true,
          merge_trains_enabled: true
        }
      end

      it 'enables merge pipelines and merge trains' do
        expect(project.merge_pipelines_enabled?).to eq(true)
        expect(project.merge_trains_enabled?).to eq(true)
      end
    end
  end

  describe 'when the inbound_job_token_scope parameter is not provided' do
    let(:mutation_params) do
      {
        full_path: project.full_path,
        merge_pipelines_enabled: true,
        merge_trains_enabled: true
      }
    end

    it 'does not log an audit event' do
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

      subject
    end
  end

  describe 'inbound_job_token_scope_enabled' do
    let(:mutation_params) do
      {
        full_path: project.full_path,
        inbound_job_token_scope_enabled: inbound_job_token_scope_enabled_target
      }
    end

    let(:project) do
      create(:project,
        keep_latest_artifact: true,
        ci_inbound_job_token_scope_enabled: inbound_job_token_scope_enabled_origin
      )
    end

    let(:ci_cd_settings) { project.ci_cd_settings }

    let(:expected_target) do
      project.ci_cd_settings
    end

    let(:expected_audit_context) do
      {
        name: event_name,
        author: user,
        scope: project,
        target: expected_target,
        message: expected_audit_message
      }
    end

    before do
      ci_cd_settings.update!(inbound_job_token_scope_enabled: inbound_job_token_scope_enabled_origin)
    end

    context 'when changes from enabled to disabled' do
      let(:inbound_job_token_scope_enabled_origin) { true }
      let(:inbound_job_token_scope_enabled_target) { false }
      let(:expected_audit_message) { 'Secure ci_job_token was disabled for inbound' }
      let(:event_name) { 'secure_ci_job_token_inbound_disabled' }

      it 'logs an audit event' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(expected_audit_context))

        subject
      end
    end

    context 'when changes from disabled to enabled' do
      let(:inbound_job_token_scope_enabled_origin) { false }
      let(:inbound_job_token_scope_enabled_target) { true }
      let(:expected_audit_message) { 'Secure ci_job_token was enabled for inbound' }
      let(:event_name) { 'secure_ci_job_token_inbound_enabled' }

      it 'logs an audit event' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(expected_audit_context))

        subject
      end
    end

    context 'when there are no changes' do
      let(:inbound_job_token_scope_enabled_origin) { true }
      let(:inbound_job_token_scope_enabled_target) { true }

      it 'does not log an audit event' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        subject
      end
    end
  end
end
