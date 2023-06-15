# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ci Catalog', :js, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:project) { create(:project, :repository, namespace: namespace) }
  let_it_be(:project2) do
    create(
      :project, :with_avatar,
      :repository,
      name: 'Component Repository',
      description: 'A simple component',
      namespace: namespace
    )
  end

  let_it_be(:resource) { create(:catalog_resource, project: project2) }

  before do
    namespace.add_developer(user)
    stub_licensed_features(ci_namespace_catalog: true)

    sign_in(user)
  end

  describe 'GET /:project/-/ci/catalog/resources' do
    before do
      visit project_ci_catalog_resources_path(project)
      wait_for_requests
    end

    it 'shows CI Catalog title and description', :aggregate_failures do
      expect(page).to have_content('CI/CD Catalog')
      expect(page).to have_content('Repositories of pipeline components available in this namespace.')
    end
  end

  describe 'GET /:project/-/ci/catalog/resources/:id' do
    before do
      # This can be replaced when clicking on the list item of a catalog item
      # will take you to the details page. For now, we manually get the id
      # and navigate to the page directly.
      resource_id = Ci::Catalog::Resource.where(project_id: project2.id)[0].id
      visit project_ci_catalog_resource_path(project, id: resource_id)
      wait_for_requests
    end

    it 'shows CI Catalog title in id page' do
      expect(page).to have_content('About this project')
    end
  end
end
