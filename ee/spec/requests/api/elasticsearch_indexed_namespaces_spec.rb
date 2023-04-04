# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ElasticsearchIndexedNamespaces, :aggregate_failures, feature_category: :global_search do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin) { create(:user) }

  shared_examples 'rollout related' do
    context 'when parameters are incorrect' do
      using RSpec::Parameterized::TableSyntax

      where(:percentage, :plan) do
        -1    | 'ultimate'
        101   | 'ultimate'
        nil   | 'ultimate'
        1     | nil
        1     | 'foobar'
      end

      with_them do
        it 'errs' do
          put api(path, admin, admin_mode: true), params: { plan: plan, percentage: percentage }
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    it 'prohibits non-admin' do
      put api(path, non_admin), params: { plan: 'ultimate', percentage: 50 }
      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'PUT /elasticsearch_indexed_namespaces/rollout' do
    let(:path) { "/elasticsearch_indexed_namespaces/rollout" }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { plan: 'ultimate', percentage: 50 } }
    end

    include_context 'rollout related'

    it 'invokes ElasticNamespaceRolloutWorker rollout' do
      expect(ElasticNamespaceRolloutWorker).to receive(:perform_async).with('ultimate', 50, ElasticNamespaceRolloutWorker::ROLLOUT)

      put api(path, admin, admin_mode: true), params: { plan: 'ultimate', percentage: 50 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'PUT /elasticsearch_indexed_namespaces/rollback' do
    let(:path) { "/elasticsearch_indexed_namespaces/rollback" }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { plan: 'ultimate', percentage: 50 } }
    end

    include_context 'rollout related'

    it 'invokes ElasticNamespaceRolloutWorker rollback' do
      expect(ElasticNamespaceRolloutWorker).to receive(:perform_async).with('ultimate', 50, ElasticNamespaceRolloutWorker::ROLLBACK)

      put api(path, admin, admin_mode: true), params: { plan: 'ultimate', percentage: 50 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
