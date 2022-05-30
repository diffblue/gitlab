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

      context 'when prometheus_computed_alerts feature is disabled' do
        before do
          stub_feature_flags(prometheus_computed_alerts: false)
        end

        it 'alerts-endpoint is nil' do
          expect(subject['alerts-endpoint']).to be_nil
        end

        it 'prometheus-alerts-available is nil' do
          expect(subject['prometheus-alerts-available']).to be_nil
        end
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
