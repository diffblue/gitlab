# frozen_string_literal: true

class ElasticRemoveExpiredNamespaceSubscriptionsFromIndexCronWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include Gitlab::ExclusiveLeaseHelpers
  include CronjobQueue

  feature_category :global_search
  tags :exclude_from_kubernetes
  idempotent!

  def perform
    return unless ::Gitlab.dev_env_or_com?

    in_lock(self.class.name.underscore, ttl: 1.hour, retries: 0) do
      GitlabSubscription.yield_long_expired_indexed_namespaces do |indexed_namespace|
        with_context(namespace: indexed_namespace.namespace, caller_id: self.class.name) do
          indexed_namespace.destroy!
        end
      end
    end
  end
end
