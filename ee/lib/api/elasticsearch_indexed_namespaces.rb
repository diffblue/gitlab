# frozen_string_literal: true

module API
  class ElasticsearchIndexedNamespaces < ::API::Base
    before { authenticated_as_admin! }

    feature_category :global_search
    urgency :low

    resource :elasticsearch_indexed_namespaces do
      desc 'Rollout namespaces to be indexed up to n%' do
        detail <<~END
          This feature was introduced in GitLab 12.7.

          This will only ever increase the number of indexed namespaces. Providing a value lower than the current rolled out percentage will have no effect.

          This percentage is never persisted but is used to calculate the number of new namespaces to rollout.

          If the same percentage is applied again at a later time, due to possible new namespaces being created during the period, some of them will also be indexed. Therefore you may expect that setting this to 10%, then waiting a month and setting to 10% again will trigger new namespaces to be added (i.e. 10% of the number of newly created namespaces in the last month within the given plan).
        END
      end
      params do
        requires :percentage, type: Integer, values: 0..100
        requires :plan, type: String, values: Plan::PAID_HOSTED_PLANS
      end
      put 'rollout' do
        ElasticNamespaceRolloutWorker.perform_async(params[:plan], params[:percentage], ElasticNamespaceRolloutWorker::ROLLOUT) # rubocop:disable CodeReuse/Worker
      end

      desc 'Rollback namespaces to be indexed down to n%' do
        detail <<~END
          This feature was introduced in GitLab 12.7.

          This will only ever decrease the number of indexed namespaces. Providing a value higher than the current rolled out percentage will have no effect.

          This percentage is never persisted but is used to calculate the number of namespaces to rollback.
        END
      end
      params do
        requires :percentage, type: Integer, values: 0..100
        requires :plan, type: String, values: Plan::PAID_HOSTED_PLANS
      end
      put 'rollback' do
        ElasticNamespaceRolloutWorker.perform_async(params[:plan], params[:percentage], ElasticNamespaceRolloutWorker::ROLLBACK) # rubocop:disable CodeReuse/Worker
      end
    end
  end
end
