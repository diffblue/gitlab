# frozen_string_literal: true

class ResourceWeightEvent < ResourceEvent
  validates :issue, presence: true

  scope :aliased_for_timebox_report, -> do
    select("'weight' AS event_type", "id", "created_at", "weight AS value", "NULL AS action", "issue_id")
  end

  def synthetic_note_class
    WeightNote
  end

  def issuable
    issue
  end
end
