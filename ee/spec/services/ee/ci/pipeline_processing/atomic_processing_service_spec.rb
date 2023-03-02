# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineProcessing::AtomicProcessingService, feature_category: :continuous_integration do
  describe 'Pipeline Processing Service' do
    let(:project) { create(:project, :repository) }
    let(:user)    { project.first_owner }

    let(:pipeline) do
      create(:ci_empty_pipeline, ref: 'master', project: project)
    end

    context 'when protected environments are defined', :sidekiq_inline do
      let(:staging_job) { create_build('staging:deploy', environment: 'staging', user: user) }
      let(:production_job) { create_build('production:deploy', environment: 'production', user: user) }

      before do
        stub_licensed_features(protected_environments: true)

        # Protection for the staging environment
        staging = create(:environment, name: 'staging', project: project)
        create(:protected_environment, name: 'staging', project: project, authorize_user_to_deploy: user)
        create(:deployment, environment: staging, deployable: staging_job, project: project)

        # Protection for the production environment (with Deployment Approvals)
        production = create(:environment, name: 'production', project: project)
        create(:protected_environment, name: 'production', project: project, authorize_user_to_deploy: user, required_approval_count: 1)
        create(:deployment, environment: production, deployable: production_job, project: project)
      end

      it 'blocks pipeline on stage with first manual action' do
        process_pipeline

        expect(builds_names).to match_array %w[staging:deploy production:deploy]
        expect(staging_job.reload).to be_pending
        expect(staging_job.deployment).to be_created
        expect(production_job.reload).to be_manual
        expect(production_job.deployment).to be_blocked
        expect(pipeline.reload).to be_running
      end
    end

    private

    def all_builds
      pipeline.processables.order(:stage_idx, :id)
    end

    def builds
      all_builds.where.not(status: [:created, :skipped])
    end

    def builds_names
      builds.pluck(:name)
    end

    def create_build(name, **opts)
      create(:ci_build, :created, pipeline: pipeline, name: name, **opts)
    end
  end

  private

  def process_pipeline
    described_class.new(pipeline).execute
  end
end
