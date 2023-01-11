# frozen_string_literal: true

class ResourceWeightEvent < ResourceEvent
  validates :issue, presence: true

  def synthetic_note_class
    WeightNote
  end

  def issuable
    issue
  end
end
