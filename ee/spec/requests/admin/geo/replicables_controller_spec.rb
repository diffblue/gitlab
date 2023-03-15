# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Geo::ReplicablesController, :geo, feature_category: :geo_replication do
  include AdminModeHelper
  include EE::GeoHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:primary_node) { create(:geo_node) }
  let_it_be(:secondary_node) { create(:geo_node, :secondary) }

  let(:replicable_name) { 'replicable' }
  let(:replicable_class) { class_double("Gitlab::Geo::Replicator", replicable_name_plural: 'replicables', graphql_field_name: 'graphql', verification_enabled?: true) }

  before do
    enable_admin_mode!(admin)
    login_as(admin)
  end

  subject do
    get url
    response
  end

  shared_examples 'license required' do
    context 'without a valid license' do
      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end
  end

  describe 'GET /admin/geo/replicables/:replicable_name_plural' do
    let(:url) { "/admin/geo/replication/#{replicable_name}" }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
        allow(::Gitlab::Geo::Replicator).to receive(:for_replicable_name)
          .with(replicable_name).and_return(replicable_class)

        get url
      end

      context 'when Geo is not enabled' do
        it { is_expected.to redirect_to(admin_geo_nodes_path) }
      end

      context 'when on a Geo primary' do
        before do
          stub_primary_node
        end

        it { is_expected.to redirect_to(admin_geo_nodes_path) }
      end

      context 'when on a Geo secondary' do
        before do
          stub_current_geo_node(secondary_node)
        end

        it do
          is_expected.to redirect_to(
            site_replicables_admin_geo_node_path(id: secondary_node.id, replicable_name_plural: replicable_name)
          )
        end
      end
    end
  end

  describe 'GET /admin/geo/sites/:id/replicables/:replicable_name_plural' do
    let(:url) { "/admin/geo/sites/#{secondary_node.id}/replication/#{replicable_name}" }

    it_behaves_like 'license required'

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
        allow(::Gitlab::Geo::Replicator).to receive(:for_replicable_name)
          .with(replicable_name).and_return(replicable_class)
      end

      where(:current_node) { [nil, lazy { primary_node }, lazy { secondary_node }] }

      with_them do
        context 'loads node data' do
          before do
            stub_current_geo_node(current_node) if current_node.present?
          end

          it { is_expected.not_to be_redirect }

          it 'includes expected current and target ids' do
            get url

            expect(response.body).to include("geo-target-site-id=\"#{secondary_node.id}\"")
            if current_node.present?
              expect(response.body).to include("geo-current-site-id=\"#{current_node&.id}\"")
            else
              expect(response.body).not_to include("geo-current-site-id")
            end
          end
        end
      end
    end
  end
end
