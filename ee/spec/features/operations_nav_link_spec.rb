# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Operations dropdown navbar EE', :js, feature_category: :navigation do
  include Features::TopNavSpecHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    stub_licensed_features(operations_dashboard: true)

    visit project_issues_path(project)
  end

  it 'has an `Operations` link' do
    open_top_nav

    expect(page).to have_link('Operations', href: operations_path)
  end

  it 'has an `Environments` link' do
    open_top_nav

    expect(page).to have_link('Environments', href: operations_environments_path)
  end
end
