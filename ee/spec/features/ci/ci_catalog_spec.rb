# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ci Catalog', :js, feature_category: :pipeline_composition do
  let(:user) { create(:user) }
  let(:namespace) { build(:namespace) }
  let(:project) { build(:project, :repository, namespace: namespace) }

  before do
    project.add_developer(user)
    stub_licensed_features(ci_namespace_catalog: true)

    sign_in(user)
  end

  describe 'GET /:project/-/ci/catalog/resources' do
    before do
      visit project_ci_catalog_resources_path(project)
      wait_for_requests
    end

    it 'shows CI Catalog title and description', :aggregate_failures do
      expect(page).to have_content('CI/CD catalog')
      expect(page).to have_content('Repositories of pipeline components available in this namespace.')
    end
  end

  describe 'GET /:project/-/ci/catalog/resources/:id' do
    before do
      visit project_ci_catalog_resource_path(project, id: 1)
      wait_for_requests
    end

    it 'shows CI Catalog title in id page' do
      expect(page).to have_content('Catalog item details page')
    end
  end
end
