# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Merge request > User sees merge widget', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'when merge pipelines option is enabled at project level configuration' do
    before do
      stub_licensed_features(merge_pipelines: true)
      project.update!(merge_pipelines_enabled: true)
    end

    let!(:merge_request) do
      create(:merge_request,
        *traits,
        source_project: source_project,
        source_branch: 'feature',
        target_project: target_project,
        target_branch: 'master',
        **options)
    end

    let(:target_project) { project }
    let(:source_project) { project }

    context 'when the head pipeline is merge request pipeline' do
      let(:traits) { [:with_merge_request_pipeline] }
      let(:options) { {} }

      before do
        merge_request.update_head_pipeline
        merge_request.all_pipelines.first.succeed!
      end

      it 'does not show any warnings' do
        visit project_merge_request_path(project, merge_request)

        expect(page).not_to have_css('.danger_message')
      end
    end

    context 'when the head pipeline is merge train pipeline' do
      let(:traits) { [:with_merge_train_pipeline] }
      let(:options) { { merge_sha: project.commit.sha } }
      let(:pipeline) { merge_request.all_pipelines.first }

      before do
        merge_request.update_head_pipeline
      end

      it 'shows head pipeline information' do
        visit project_merge_request_path(project, merge_request)

        within '.ci-widget-content' do
          expect(page).to have_content("Merge train pipeline ##{pipeline.id} pending for #{pipeline.short_sha}")
        end
      end
    end

    context 'when merge request is submitted from a forked project' do
      let(:source_project) { fork_project(project, user, repository: true) }
      let(:traits) { [:with_detached_merge_request_pipeline] }
      let(:options) { {} }

      it 'shows a warning that fork project merge request does not create merge request pipelines by default', :sidekiq_might_not_need_inline do
        visit project_merge_request_path(project, merge_request)

        expect(page).to have_content('If the last pipeline ran in the fork project, it may be inaccurate.')
      end
    end
  end
end
