# frozen_string_literal: true

module PackageMetadata
  class AdvisoryScanWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :delayed
    feature_category :software_composition_analysis
    urgency :low
    idempotent!

    def handle_event(event)
      advisory = Advisory.with_affected_packages.find_by_id(event.data[:advisory_id])

      if advisory.nil?
        return logger.info(structured_payload(message: 'Advisory not found.', advisory_id: event.data[:advisory_id]))
      end

      AdvisoryScanService.execute(advisory)
    end
  end
end
