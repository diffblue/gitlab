# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Replication Nav', :js, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include StubENV

  let_it_be(:admin) { create(:admin) }
  let_it_be(:secondary_node) { create(:geo_node) }

  before do
    stub_licensed_features(geo: true)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    stub_current_geo_node(secondary_node)
    stub_geo_setting(registry_replication: { enabled: true })
  end

  shared_examples 'active sidebar link' do |link_name|
    before do
      visit path
      wait_for_requests
    end

    it 'has active class' do
      navigation_link = page.find('a', text: link_name)
      expect(navigation_link[:class]).to include('active')
    end
  end

  describe 'visit admin/geo/replication/projects' do
    it_behaves_like 'active sidebar link', 'Projects' do
      let(:path) { admin_geo_replicables_path(replicable_name_plural: 'projects') }
    end
  end

  describe 'visit admin/geo/replication/designs' do
    it_behaves_like 'active sidebar link', 'Designs' do
      let(:path) { admin_geo_replicables_path(replicable_name_plural: 'designs') }
    end
  end

  describe 'visit admin/geo/replication/*' do
    Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
      it_behaves_like 'active sidebar link', replicator_class.replicable_title_plural do
        let(:path) { admin_geo_replicables_path(replicable_name_plural: replicator_class.replicable_name_plural) }
      end
    end

    it 'displays enabled replicator replication details nav links' do
      visit admin_geo_replicables_path(replicable_name_plural: 'projects')

      Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
        navbar = page.find(".gl-tabs-nav")

        expect(navbar).to have_link replicator_class.replicable_title_plural
      end
    end
  end
end
