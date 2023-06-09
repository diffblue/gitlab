# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ClustersController, feature_category: :deployment_management do
  include AccessMatchersForController

  let_it_be(:group) { create(:group) }

  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  it_behaves_like 'cluster metrics' do
    let(:user) { create(:user) }
    let(:clusterable) { group }

    let(:cluster) do
      create(:cluster, :group, :provided_by_gcp, groups: [group])
    end

    let(:metrics_params) do
      {
        group_id: group,
        id: cluster
      }
    end

    before do
      clusterable.add_maintainer(user)
    end

    describe 'security' do
      let(:prometheus_adapter) { double(:prometheus_adapter, can_query?: true, query: nil) }

      before do
        sign_in(user)
        allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it { expect { go }.to be_allowed_for(:admin) }
      end

      context 'when admin mode is disabled' do
        it { expect { go }.to be_denied_for(:admin) }
      end

      it { expect { go }.to be_allowed_for(:owner).of(clusterable) }
      it { expect { go }.to be_allowed_for(:maintainer).of(clusterable) }
      it { expect { go }.to be_denied_for(:developer).of(clusterable) }
      it { expect { go }.to be_denied_for(:reporter).of(clusterable) }
      it { expect { go }.to be_denied_for(:guest).of(clusterable) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'GET environments' do
    let(:cluster) { create(:cluster_for_group, groups: [group]) }

    before do
      create(:deployment, :success)
    end

    def get_cluster_environments
      get :environments,
        params: {
          group_id: group.to_param,
          id: cluster
        },
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
      context 'when admin mode is enabled', :enable_admin_mode do
        it { expect { get_cluster_environments }.to be_allowed_for(:admin) }
      end

      context 'when admin mode is disabled' do
        it { expect { get_cluster_environments }.to be_denied_for(:admin) }
      end

      it { expect { get_cluster_environments }.to be_allowed_for(:owner).of(group) }
      it { expect { get_cluster_environments }.to be_allowed_for(:maintainer).of(group) }
      it { expect { get_cluster_environments }.to be_denied_for(:developer).of(group) }
      it { expect { get_cluster_environments }.to be_denied_for(:reporter).of(group) }
      it { expect { get_cluster_environments }.to be_denied_for(:guest).of(group) }
      it { expect { get_cluster_environments }.to be_denied_for(:user) }
      it { expect { get_cluster_environments }.to be_denied_for(:external) }
    end
  end

  describe 'GET show' do
    let(:cluster) { create(:cluster_for_group, groups: [group]) }

    def get_cluster
      get :show,
        params: {
          group_id: group,
          id: cluster
        }
    end

    it 'expires etag cache to force reload environments list' do
      stub_licensed_features(cluster_deployments: true)
      expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
        expect(store).to receive(:touch)
          .with(environments_group_cluster_path(cluster.group, cluster))
          .and_call_original
      end

      get_cluster
    end
  end
end
