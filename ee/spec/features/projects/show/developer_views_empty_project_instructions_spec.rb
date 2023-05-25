# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > Developer views empty project instructions', feature_category: :groups_and_projects do
  let(:project) { create(:project, :empty_repo) }
  let(:developer) { create(:user) }

  before do
    project.add_developer(developer)

    sign_in(developer)
  end

  context 'with Kerberos enabled' do
    before do
      allow(Gitlab.config.kerberos).to receive(:enabled).and_return(true)
    end

    it 'defaults to KRB5' do
      visit project_path(project)

      expect(page).to have_content("git clone #{project.kerberos_url_to_repo}")
    end
  end
end
