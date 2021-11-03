# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::External, :saas do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:subscription) { create(:gitlab_subscription, :default, namespace: user.namespace) }

  let(:pipeline) { build(:ci_empty_pipeline, user: user, project: project) }

  let(:ci_yaml) do
    <<-CI_YAML
    job:
      script: ls
      parallel: 5
    CI_YAML
  end

  let(:yaml_processor_result) do
    ::Gitlab::Ci::YamlProcessor.new(
      ci_yaml, {
        project: project,
        sha: pipeline.sha,
        user: user
      }
    ).execute
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user, yaml_processor_result: yaml_processor_result, save_incompleted: true
    )
  end

  let(:step) { described_class.new(pipeline, command) }
  let(:validation_service_url) { 'https://validation-service.external/' }

  describe '#validation_service_payload' do
    before do
      stub_env('EXTERNAL_VALIDATION_SERVICE_URL', validation_service_url)
    end

    it 'respects the defined schema and returns the default plan' do
      expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
        expect(params[:body]).to match_schema('/external_validation', dir: 'ee')

        payload = Gitlab::Json(params[:body])
        expect(payload.dig('namespace', 'plan')).to eq('default')
        expect(payload.dig('namespace', 'trial')).to be false
      end

      step.perform!
    end

    it 'does not fire N+1 SQL queries' do
      stub_request(:post, validation_service_url)

      expect { step.perform! }.not_to exceed_query_limit(16)
    end

    context 'with a project in a subgroup' do
      let(:group) { create(:group_with_plan, plan: :ultimate_plan, trial_ends_on: Date.tomorrow) }
      let(:subgroup) { create(:group, parent: group) }
      let(:project) { create(:project, namespace: subgroup, shared_runners_enabled: true) }

      it 'returns an Ultimate plan on trial' do
        expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
          expect(params[:body]).to match_schema('/external_validation', dir: 'ee')

          payload = Gitlab::Json.parse(params[:body])
          expect(payload.dig('namespace', 'plan')).to eq('ultimate')
          expect(payload.dig('namespace', 'trial')).to be true
          expect(payload.dig('provisioning_group')).be_nil
        end

        step.perform!
      end

      context 'when user is provisioned by group' do
        let(:user) { create(:user) }

        before do
          user.provisioned_by_group = group
        end

        it 'returns the provisioned group with an Ultimate plan' do
          expect(::Gitlab::HTTP).to receive(:post) do |_url, params|
            expect(params[:body]).to match_schema('/external_validation', dir: 'ee')

            payload = Gitlab::Json.parse(params[:body])
            expect(payload.dig('provisioning_group', 'plan')).to eq('ultimate')
            expect(payload.dig('provisioning_group', 'trial')).to be true
          end

          step.perform!
        end
      end
    end
  end
end
