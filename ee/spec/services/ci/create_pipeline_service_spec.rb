# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, '#execute' do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:ultimate_plan) { create(:ultimate_plan) }
  let_it_be(:plan_limits) { create(:plan_limits, plan: ultimate_plan) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }
  let_it_be(:user) { create(:user) }

  let(:ref_name) { 'master' }

  let(:service) do
    params = { ref: ref_name,
               before: '00000000',
               after: project.commit.id,
               commits: [{ message: 'some commit' }] }

    described_class.new(project, user, params)
  end

  before do
    create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)

    project.add_developer(user)
    stub_ci_pipeline_to_return_yaml_file
  end

  describe 'CI/CD Quotas / Limits' do
    context 'when there are not limits enabled' do
      it 'enqueues a new pipeline', :aggregate_failures do
        response, pipeline = create_pipeline!

        expect(response).to be_success
        expect(pipeline).to be_created_successfully
      end
    end

    context 'when pipeline activity limit is exceeded' do
      before do
        plan_limits.update_column(:ci_active_pipelines, 2)

        create(:ci_pipeline, project: project, status: 'pending')
        create(:ci_pipeline, project: project, status: 'running')
      end

      it 'drops the pipeline and does not process jobs', :aggregate_failures do
        response, pipeline = create_pipeline!

        expect(response).to be_error
        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.statuses).not_to be_empty
        expect(pipeline.statuses).to all(be_created)
        expect(pipeline.activity_limit_exceeded?).to be true
      end
    end

    context 'when pipeline size limit is exceeded' do
      before do
        plan_limits.update_column(:ci_pipeline_size, 2)
      end

      it 'drops pipeline without creating jobs', :aggregate_failures do
        response, pipeline = create_pipeline!

        expect(response).to be_error
        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.statuses).to be_empty
        expect(pipeline.size_limit_exceeded?).to be true
      end
    end
  end

  describe 'cross-project pipeline triggers' do
    before do
      stub_ci_pipeline_yaml_file <<~YAML
        test:
          script: rspec

        deploy:
          variables:
            CROSS: downstream
          stage: deploy
          trigger: my/project
      YAML
    end

    it 'creates bridge jobs correctly', :aggregate_failures do
      response, pipeline = create_pipeline!

      test = pipeline.statuses.find_by(name: 'test')
      bridge = pipeline.statuses.find_by(name: 'deploy')

      expect(response).to be_success
      expect(pipeline).to be_persisted
      expect(test).to be_a Ci::Build
      expect(bridge).to be_a Ci::Bridge
      expect(bridge.stage).to eq 'deploy'
      expect(pipeline.statuses).to match_array [test, bridge]
      expect(bridge.options).to eq(trigger: { project: 'my/project' })
      expect(bridge.yaml_variables)
        .to include(key: 'CROSS', value: 'downstream', public: true)
    end

    context 'when configured with rules' do
      before do
        stub_ci_pipeline_yaml_file(config)
      end

      let(:downstream_project) { create(:project, :repository) }

      let(:config) do
        <<-EOY
          hello:
            script: echo world

          bridge-job:
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"
            trigger:
              project: #{downstream_project.full_path}
              branch: master
        EOY
      end

      context 'that include the bridge job' do
        it 'persists the bridge job' do
          _, pipeline = create_pipeline!

          expect(pipeline.processables.pluck(:name)).to contain_exactly('hello', 'bridge-job')
        end
      end

      context 'that exclude the bridge job' do
        let(:ref_name) { 'refs/heads/wip' }

        it 'does not include the bridge job' do
          _, pipeline = create_pipeline!

          expect(pipeline.processables.pluck(:name)).to eq(%w[hello])
        end
      end
    end
  end

  describe 'job with secrets' do
    before do
      stub_ci_pipeline_yaml_file <<~YAML
        deploy:
          script:
            - echo
          secrets:
            DATABASE_PASSWORD:
              vault: production/db/password
      YAML
    end

    it 'persists secrets as job metadata', :aggregate_failures do
      response, pipeline = create_pipeline!

      expect(response).to be_success
      expect(pipeline).to be_persisted

      build = Ci::Build.find(pipeline.builds.first.id)

      expect(build.metadata.secrets).to eq({
        'DATABASE_PASSWORD' => {
          'vault' => {
            'engine' => { 'name' => 'kv-v2', 'path' => 'kv-v2' },
            'path' => 'production/db',
            'field' => 'password'
          }
        }
      })
    end
  end

  describe 'credit card requirement' do
    shared_examples 'creates a successful pipeline' do
      it 'creates a successful pipeline', :aggregate_failures do
        response, pipeline = create_pipeline!

        expect(response).to be_success
        expect(pipeline).to be_created_successfully
      end
    end

    context 'when credit card is required' do
      context 'when project is on free plan' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(true)
          namespace.gitlab_subscription.update!(hosted_plan: create(:free_plan))
          user.created_at = ::Users::CreditCardValidation::RELEASE_DAY
        end

        context 'when user has credit card' do
          before do
            allow(user).to receive(:credit_card_validated_at).and_return(Time.current)
          end

          it_behaves_like 'creates a successful pipeline'
        end

        context 'when user does not have credit card' do
          it 'creates a pipeline with errors', :aggregate_failures do
            _, pipeline = create_pipeline!

            expect(pipeline).not_to be_created_successfully
            expect(pipeline.failure_reason).to eq('user_not_verified')
          end

          context 'when config is blank' do
            before do
              stub_ci_pipeline_yaml_file(nil)
            end

            it 'does not create a pipeline', :aggregate_failures do
              response, pipeline = create_pipeline!

              expect(response).to be_error
              expect(pipeline).not_to be_persisted
            end
          end

          context 'when feature flag is disabled' do
            before do
              stub_feature_flags(ci_require_credit_card_on_free_plan: false)
            end

            it_behaves_like 'creates a successful pipeline'
          end
        end
      end
    end

    context 'when credit card is not required' do
      it_behaves_like 'creates a successful pipeline'
    end
  end

  def create_pipeline!
    response = service.execute(:push)

    [response, response.payload]
  end
end
