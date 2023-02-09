# frozen_string_literal: true

module ResourceEvents
  class ChangeWeightService
    attr_reader :resource, :user

    def initialize(resource, user)
      @resource = resource
      @user = user
    end

    def execute
      ids = ::ApplicationRecord.legacy_bulk_insert( # rubocop:disable Gitlab/BulkInsert
        ResourceWeightEvent.table_name, resource_weight_changes, return_ids: true
      )
      ResourceWeightEvent.id_in(ids).with_work_item.each(&:trigger_note_subscription_create)

      resource.expire_note_etag_cache

      if resource.is_a?(WorkItem)
        Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter.track_work_item_weight_changed_action(author: user)
      else
        tracking_data = { author: user, project: resource.project }
        Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_weight_changed_action(**tracking_data)
      end
    end

    private

    def resource_weight_changes
      changes = []
      base_data = { user_id: user.id, issue_id: resource.id }

      changes << base_data.merge({ weight: resource.previous_weight, created_at: resource.previous_updated_at }) if resource.first_weight_event?
      changes << base_data.merge({ weight: resource.weight, created_at: resource.system_note_timestamp })

      changes
    end
  end
end
