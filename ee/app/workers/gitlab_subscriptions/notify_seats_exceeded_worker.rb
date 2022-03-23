# frozen_string_literal: true

module GitlabSubscriptions
  class NotifySeatsExceededWorker
    include Gitlab::EventStore::Subscriber

    feature_category :purchase
    data_consistency :delayed
    deduplicate :until_executing, including_scheduled: true

    idempotent!
    worker_has_external_dependencies!

    def handle_event(event)
      source = case event.data[:source_type]
               when 'Group'
                 Group.find_by_id(event.data[:source_id])
               when 'Project'
                 Project.find_by_id(event.data[:source_id])
               else
                 nil
               end

      return unless source&.root_ancestor.present?

      GitlabSubscriptions::NotifySeatsExceededService.new(source.root_ancestor).execute
    end
  end
end
