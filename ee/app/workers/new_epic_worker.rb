# frozen_string_literal: true

class NewEpicWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include NewIssuable

  feature_category :epics
  worker_resource_boundary :cpu
  weight 2

  def perform(epic_id, user_id)
    return unless objects_found?(epic_id, user_id)

    EventCreateService.new.open_epic(issuable, user)
    NotificationService.new.new_epic(issuable, user)
    issuable.create_cross_references!(user)
  end

  def issuable_class
    Epic
  end
end
