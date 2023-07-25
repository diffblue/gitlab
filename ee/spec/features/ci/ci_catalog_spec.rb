# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ci Catalog', :js, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:project) { create(:project, :repository, namespace: namespace) }
  let(:ci_resource_projects) do
    create_list(
      :project,
      3,
      :repository,
      description: 'A simple component',
      namespace: namespace
    )
  end

  before do
    ci_resource_projects.each do |current_project|
      create(:catalog_resource, project: current_project)
    end

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

    it 'renders CI Catalog resources list' do
      expect(find_all('[data-testid="catalog-resource-item"]').length).to be(3)
    end

    context 'for a single CI/CD catalog resource' do
      it 'renders resource details', :aggregate_failures do
        page.within('[data-testid="catalog-resource-item"]', match: :first) do
          expect(page).to have_content("Name")
          expect(page).to have_content("A simple component")
          expect(page).to have_content(namespace.name)
        end
      end

      context 'when clicked' do
        before do
          find('[data-testid="ci-resource-link"]', match: :first).click
        end

        it 'navigate to the details page', :aggregate_failures do
          expect(page).to have_content('About this project')
        end
      end
    end
  end

  describe 'GET /:project/-/ci/catalog/resources/:id' do
    before do
      visit project_ci_catalog_resources_path(project)
      wait_for_requests
      find('[data-testid="ci-resource-link"]', match: :first).click
    end

    it 'shows CI Catalog title in details page' do
      expect(page).to have_content('About this project')
    end
  end
end
