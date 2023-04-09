# frozen_string_literal: true

class ResourceIterationEvent < ResourceTimeboxEvent
  include EachBatch

  belongs_to :iteration

  scope :with_api_entity_associations, -> { preload(:iteration, :user) }
  scope :by_user, -> (user) { where(user_id: user) }

  scope :aliased_for_timebox_report, -> do
    select("'timebox' AS event_type", "id", "created_at", "iteration_id AS value", "action", "issue_id")
  end

  def synthetic_note_class
    IterationNote
  end
end
