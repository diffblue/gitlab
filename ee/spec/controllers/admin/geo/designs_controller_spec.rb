# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Geo::DesignsController, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  describe 'GET #index' do
    let_it_be(:node) { create(:geo_node) }

    before do
      stub_current_geo_node(node)
      stub_licensed_features(geo: true)
      sign_in(create(:admin))
    end

    shared_examples 'redirects /admin/geo/replication/designs' do
      it do
        get :index

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to(
          "/admin/geo/sites/#{node.id}/replication/design_management_repositories"
        )
      end
    end

    context 'when feature flag geo_design_management_repository_replication is enabled' do
      before do
        stub_feature_flags(geo_design_management_repository_replication: true)
      end

      context 'on primary' do
        before do
          stub_primary_node
        end

        it_behaves_like 'redirects /admin/geo/replication/designs'
      end

      context 'on secondary' do
        before do
          stub_secondary_node
        end

        it_behaves_like 'redirects /admin/geo/replication/designs'
      end
    end

    context 'when feature flag geo_design_management_repository_replication is disabled' do
      before do
        stub_feature_flags(geo_design_management_repository_replication: false)
      end

      it 'retuns status ok' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
