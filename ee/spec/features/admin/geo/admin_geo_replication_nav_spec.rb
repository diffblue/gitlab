# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Replication Nav', :js, :geo do
  include ::EE::GeoHelpers
  include StubENV

  let_it_be(:admin) { create(:admin) }

  before do
    stub_licensed_features(geo: true)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    stub_secondary_node
  end

  shared_examples 'active sidebar link' do |link_name|
    before do
      visit path
      wait_for_requests
    end

    it 'has active class' do
      navigation_link = page.find("a[title=\"#{link_name}\"]").find(:xpath, '..')
      expect(navigation_link[:class]).to include('active')
    end
  end

  describe 'visit admin/geo/replication/projects' do
    it_behaves_like 'active sidebar link', 'Projects' do
      let(:path) { admin_geo_projects_path }
    end
  end

  describe 'visit admin/geo/replication/designs' do
    it_behaves_like 'active sidebar link', 'Designs' do
      let(:path) { admin_geo_designs_path }
    end
  end

  describe 'visit admin/geo/replication/*' do
    Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
      it_behaves_like 'active sidebar link', replicator_class.replicable_title_plural do
        let(:path) { admin_geo_replicables_path(replicable_name_plural: replicator_class.replicable_name_plural) }
      end
    end

    it 'displays enable replicator replication details nav links' do
      visit admin_geo_replicables_path(replicable_name_plural: 'projects')

      Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
        navbar = page.find(".nav-links.nav.nav-tabs")

        expect(navbar).to have_link replicator_class.replicable_title_plural
      end
    end
  end
end
