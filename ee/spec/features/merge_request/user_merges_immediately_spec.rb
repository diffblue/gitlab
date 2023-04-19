# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge requests > User merges immediately', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let_it_be(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline,
      source_project: project, source_branch: 'feature',
      target_project: project, target_branch: 'master')
  end

  let_it_be(:ci_yaml) do
    { test: { stage: 'test', script: 'echo', only: ['merge_requests'] } }
  end

  before_all do
    project.add_maintainer(user)
    project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    merge_request.all_pipelines.first.succeed!
    merge_request.update_head_pipeline
  end

  def merge_button
    find('.mr-widget-body .accept-merge-request.btn-confirm')
  end

  def open_warning_dialog
    find('.mr-widget-body .dropdown-toggle').click

    click_button 'Merge immediately'

    expect(page).to have_selector('#merge-immediately-confirmation-dialog')
  end

  context 'when the merge request is on the merge train' do
    before do
      stub_feature_flags(disable_merge_trains: false)
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
      stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))
      stub_feature_flags(auto_merge_labels_mr_widget: false)

      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'shows a warning dialog and does nothing if the user selects "Cancel"' do
      Sidekiq::Testing.fake! do
        open_warning_dialog

        find(':focus').send_keys :enter

        expect(merge_button).to have_content('Start merge train')
      end
    end

    it 'shows a warning dialog and merges immediately after the user confirms' do
      Sidekiq::Testing.fake! do
        open_warning_dialog

        click_button 'Merge immediately'

        expect(find('[data-testid="merging-state"]')).to have_content('Merging!')
      end
    end
  end

  context 'when the merge request is on the merge train with the auto merge labels feature flag turned on' do
    before do
      stub_feature_flags(disable_merge_trains: false)
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
      stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))
      stub_feature_flags(auto_merge_labels_mr_widget: true)

      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'shows a warning dialog and does nothing if the user selects "Cancel"' do
      Sidekiq::Testing.fake! do
        open_warning_dialog

        find(':focus').send_keys :enter

        expect(merge_button).to have_content('Merge')
      end
    end

    it 'shows a warning dialog and merges immediately after the user confirms' do
      Sidekiq::Testing.fake! do
        open_warning_dialog

        click_button 'Merge immediately'

        expect(find('[data-testid="merging-state"]')).to have_content('Merging!')
      end
    end
  end
end
