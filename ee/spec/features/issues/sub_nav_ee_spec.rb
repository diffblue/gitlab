# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues sub nav EE', feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  it 'has a `Boards` item' do
    expect(find('.nav-sidebar')).to have_content 'Boards'
  end
end
