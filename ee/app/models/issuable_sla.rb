# frozen_string_literal: true

class IssuableSla < ApplicationRecord
  belongs_to :issue, optional: false
  validates :due_at, presence: true

  scope :exceeded, -> { where(label_applied: false, issuable_closed: false).where('due_at < ?', Time.current).order(:due_at, :id) }
end
