# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ClustersController do
  include AccessMatchersForController

  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  it_behaves_like 'cluster metrics' do
    let(:clusterable) { Clusters::Instance.new }

    let(:cluster) do
      create(:cluster, :instance, :provided_by_gcp)
    end

    let(:metrics_params) do
      {
        id: cluster
      }
    end

    before do
      allow(::Clusters::Instance).to receive(:new).and_return(cluster.instance)
    end
  end

  describe 'GET environments' do
    let(:cluster) { create(:cluster, :instance, :provided_by_gcp) }

    before do
      create(:deployment, :success)
    end

    def get_cluster_environments
      get :environments,
        params: { id: cluster },
        format: :json
    end

    describe 'functionality' do
      it 'responds successfully' do
        get_cluster_environments

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Poll-Interval']).to eq("5000")
      end
    end

    describe 'security' do
      it { expect { get_cluster_environments }.to be_allowed_for(:admin) }
      it { expect { get_cluster_environments }.to be_denied_for(:user) }
      it { expect { get_cluster_environments }.to be_denied_for(:external) }
    end
  end

  describe 'GET show' do
    let(:cluster) { create(:cluster, :instance, :provided_by_gcp) }

    def get_cluster
      get :show, params: { id: cluster }
    end

    it 'expires etag cache to force reload environments list' do
      stub_licensed_features(cluster_deployments: true)
      expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
        expect(store).to receive(:touch)
          .with(environments_admin_cluster_path(cluster))
          .and_call_original
      end

      get_cluster
    end
  end
end
