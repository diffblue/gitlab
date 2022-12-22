# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifactPolicy, :models do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:job) { create(:ci_build, :success, pipeline: pipeline, project: project) }

  let(:policy) do
    described_class.new(current_user, job_artifact)
  end

  describe 'rules' do
    describe 'for user without access to the project' do
      context 'when job artifact is private' do
        let(:job_artifact) { create(:ci_job_artifact, :private, job: job, project: project) }

        it 'disallows read_job_artifacts' do
          expect(policy).to be_disallowed :read_job_artifacts
        end
      end

      context 'when job artifact is public' do
        let(:job_artifact) { create(:ci_job_artifact, :public, project: project) }

        it 'allows read_job_artifacts' do
          expect(policy).to be_allowed :read_job_artifacts
        end
      end
    end

    describe 'for user with access to the project' do
      before do
        project.add_developer(current_user)
      end

      context 'when job artifact is private' do
        let(:job_artifact) { create(:ci_job_artifact, :private, job: job, project: project) }

        it 'allows read_job_artifacts' do
          expect(policy).to be_allowed :read_job_artifacts
        end
      end

      context 'when job artifact is public' do
        let(:job_artifact) { create(:ci_job_artifact, :public, project: project) }

        it 'allows read_job_artifacts' do
          expect(policy).to be_allowed :read_job_artifacts
        end
      end
    end

    describe 'for auditor user' do
      let_it_be(:current_user) { create(:user, :auditor) }

      before do
        project.add_developer(current_user)
      end

      context 'when job artifact is private' do
        let(:job_artifact) { create(:ci_job_artifact, :private, job: job, project: project) }

        it 'allows read_job_artifacts' do
          expect(policy).to be_allowed :read_job_artifacts
        end
      end

      context 'when job artifact is public' do
        let(:job_artifact) { create(:ci_job_artifact, :public, project: project) }

        it 'allows read_job_artifacts' do
          expect(policy).to be_allowed :read_job_artifacts
        end
      end
    end

    describe 'for reporter user' do
      before do
        project.add_reporter(current_user)
      end

      context 'when job artifact is private' do
        let(:job_artifact) { create(:ci_job_artifact, :private, job: job, project: project) }

        it 'disallows read_job_artifacts' do
          expect(policy).to be_disallowed :read_job_artifacts
        end
      end

      context 'when job artifact is public' do
        let(:job_artifact) { create(:ci_job_artifact, :public, project: project) }

        it 'allows read_job_artifacts' do
          expect(policy).to be_allowed :read_job_artifacts
        end
      end
    end

    describe 'for guest user' do
      let_it_be(:guest) { create(:user).tap { |user| project.add_guest(user) } }
      let(:current_user) { guest }

      context 'when job artifact is private' do
        let(:job_artifact) { create(:ci_job_artifact, :private, job: job, project: project) }

        it 'disallows read_job_artifacts' do
          expect(policy).to be_disallowed :read_job_artifacts
        end
      end

      context 'when job artifact is public' do
        let(:job_artifact) { create(:ci_job_artifact, :public, project: project) }

        it 'allows read_job_artifacts' do
          expect(policy).to be_allowed :read_job_artifacts
        end
      end
    end
  end
end
