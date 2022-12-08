# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Jobs', :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

  before do
    project.add_role(user, user_access_level)
    sign_in(user)
  end

  describe "GET /:project/jobs/:id", :js do
    context 'job project is over shared runners limit' do
      let(:group) { create(:group, :with_used_build_minutes_limit) }
      let(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }

      it 'displays a warning message' do
        visit project_job_path(project, job)
        wait_for_requests

        expect(page).to have_content('You have used 1000 out of 500 of your shared Runners pipeline minutes.')
      end
    end

    context 'job project is not over shared runners limit' do
      let(:group) { create(:group, :with_not_used_build_minutes_limit) }
      let(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }

      it 'does not display a warning message' do
        visit project_job_path(project, job)
        wait_for_requests

        expect(page).not_to have_content('You have used 1000 out of 500 of your shared Runners pipeline minutes.')
      end
    end

    context 'when job is not running', :js do
      let(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }
      let(:project) { create(:project, :repository) }

      context 'when namespace is in read-only mode' do
        it 'does not show retry button' do
          allow_next_found_instance_of(Namespace) do |instance|
            allow(instance).to receive(:read_only?).and_return(true)
          end
          visit project_job_path(project, job)
          wait_for_requests

          expect(page).not_to have_link('Retry')
          expect(page).to have_content('Job succeeded')
        end
      end
    end
  end
end
