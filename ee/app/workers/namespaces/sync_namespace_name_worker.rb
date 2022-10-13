# frozen_string_literal: true

module Namespaces
  class SyncNamespaceNameWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :saas_provisioning

    deduplicate :until_executing
    idempotent!

    worker_has_external_dependencies!

    RequestError = Class.new(StandardError)

    def perform(namespace_id)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace

      response = client.update_namespace_name(namespace.id, namespace.name)

      return if response[:success]

      raise RequestError, "Namespace name sync failed! Namespace id: #{namespace.id}, #{response}"
    end

    private

    def client
      Gitlab::SubscriptionPortal::Client
    end
  end
end
