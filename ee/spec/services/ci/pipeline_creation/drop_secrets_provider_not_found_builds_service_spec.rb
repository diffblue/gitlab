# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::DropSecretsProviderNotFoundBuildsService, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, group: group, namespace: namespace) }
  let_it_be(:build_status) { :created }
  let_it_be_with_refind(:pipeline) { create(:ci_pipeline, project: project, status: :created) }
  let!(:job) { create(:ci_build, project: pipeline.project, pipeline: pipeline, status: build_status) }

  let_it_be(:instance_runner) do
    create(:ci_runner,
      :online,
      runner_type: :instance_type,
      public_projects_minutes_cost_factor: 0,
      private_projects_minutes_cost_factor: 1)
  end

  describe '#execute' do
    subject(:service) { described_class.new(pipeline) }

    shared_examples 'does not drop the build' do
      it do
        expect_next_found_instance_of(Ci::Build) do |build|
          expect(build).not_to receive(:drop!)
        end

        service.execute
      end
    end

    shared_examples 'feature flag is disabled' do
      context 'and feature flag is disabled'
      before do
        stub_feature_flags(drop_job_on_secrets_provider_not_found: false)
      end

      it 'does not check pipeline builds' do
        expect(pipeline).not_to receive(:builds)

        service.execute
      end
    end

    context 'when build has no secrets' do
      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      it_behaves_like 'does not drop the build'

      it_behaves_like 'feature flag is disabled'
    end

    context 'when build has secrets' do
      before do
        stub_licensed_features(ci_secrets_management: true)

        rsa_key = OpenSSL::PKey::RSA.generate(3072).to_s
        stub_application_setting(ci_jwt_signing_key: rsa_key)

        job.update!(
          secrets: {
            DATABASE_PASSWORD: {
              vault: {
                engine: { name: 'kv-v2', path: 'kv-v2' },
                path: 'production/db',
                field: 'password'
              }
            }
          }
        )
      end

      context 'and secrets provider is defined' do
        before do
          create(:ci_variable, project: project, key: 'VAULT_SERVER_URL', value: 'https://vault.example.com')
        end

        it_behaves_like 'does not drop the build'

        it_behaves_like 'feature flag is disabled'
      end

      context 'and secrets provider is not defined' do
        it 'drops the build' do
          expect_next_found_instance_of(Ci::Build) do |build|
            expect(build).to receive(:drop!).with(:secrets_provider_not_found, skip_pipeline_processing: true)
          end

          service.execute
        end

        it_behaves_like 'feature flag is disabled'

        context 'and build has status different from created' do
          let_it_be(:build_status) { :pending }

          it_behaves_like 'does not drop the build'
        end
      end
    end
  end
end
