# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::ClusterPresenter do
  include Gitlab::Routing.url_helpers

  describe '#health_data' do
    shared_examples 'cluster health data' do
      let(:user) { create(:user) }
      let(:cluster_presenter) { cluster.present(current_user: user) }

      let(:clusterable_presenter) do
        ClusterablePresenter.fabricate(clusterable, current_user: user)
      end

      subject { cluster_presenter.health_data(clusterable_presenter) }

      it do
        is_expected.to include(
          'metrics-endpoint': clusterable_presenter.metrics_cluster_path(cluster, format: :json)
        )
      end
    end

    context 'with project cluster' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:clusterable) { cluster.project }

      it_behaves_like 'cluster health data'
    end

    context 'with group cluster' do
      let(:cluster) { create(:cluster, :group, :provided_by_gcp) }
      let(:clusterable) { cluster.group }

      it_behaves_like 'cluster health data'
    end
  end
end
