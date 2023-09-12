# frozen_string_literal: true

module Security
  class RefreshProjectPoliciesWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    sidekiq_options retry: true

    deduplicate :until_executing, including_scheduled: true
    idempotent!

    feature_category :security_policy_management

    def handle_event(event)
      ::Security::ScanResultPolicies::SyncProjectWorker.new.perform(event.data[:project_id])
    end
  end
end
