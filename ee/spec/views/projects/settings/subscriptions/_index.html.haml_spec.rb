# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/subscriptions/_index.html.haml' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:upstream_project) { create(:project, :public, :repository) }
  let_it_be(:downstream_project) { create(:project, :public, :repository, upstream_projects: [project]) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:project, project)
  end

  it 'has a help link' do
    render
    expect(rendered).to have_css("a[href^='/help'][href$='#trigger-a-pipeline-when-an-upstream-project-is-rebuilt']")
  end

  context 'when project has upstream subscription' do
    before do
      assign(:project, downstream_project)
    end

    it 'has delete button' do
      render
      expect(rendered).to have_selector('[data-testid="delete-subscription"].btn-danger')
    end
  end

  context 'when project has downstream subscription' do
    it 'has no delete button' do
      render
      expect(rendered).not_to have_content('No project subscribes to the pipelines in this project.')
      expect(rendered).not_to have_selector('[data-testid="delete-subscription"].btn-danger')
    end
  end
end
