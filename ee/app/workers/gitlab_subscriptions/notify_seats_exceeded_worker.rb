# frozen_string_literal: true

module GitlabSubscriptions
  class NotifySeatsExceededWorker
    include ApplicationWorker
    include Gitlab::EventStore::Subscriber

    feature_category :purchase
    data_consistency :delayed
    deduplicate :until_executing, including_scheduled: true

    idempotent!
    worker_has_external_dependencies!

    def handle_event(event)
      # no-op for now, to be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/348487
    end
  end
end
