# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Geo::DesignsController, :geo, feature_category: :geo_replication do
  describe 'GET #index' do
    let_it_be(:admin) { create(:admin) }

    before do
      allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      sign_in(admin)
    end

    context 'when feature flag geo_design_management_repository_replication is enabled' do
      before do
        stub_feature_flags(geo_design_management_repository_replication: true)
      end

      it 'redirects /admin/geo/replication/designs to admin/geo/nodes#index' do
        get :index

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to(admin_geo_nodes_path)
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
