# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE > Projects > Settings > User manages merge requests template',
  feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, namespace: user.namespace) }

  before do
    sign_in(user)
    visit project_settings_merge_requests_path(project)
  end

  it 'saves merge request template' do
    fill_in 'project_merge_requests_template', with: "This merge request should contain the following."
    page.within '#js-merge-request-settings' do
      click_button 'Save changes'
    end

    expect(find_field('project_merge_requests_template').value).to eq 'This merge request should contain the following.'
  end
end
