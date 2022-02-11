# frozen_string_literal: true

class Epic::RelatedEpicLink < ApplicationRecord
  self.table_name = 'related_epic_links'

  belongs_to :source, class_name: 'Epic'
  belongs_to :target, class_name: 'Epic'

  validates :source, presence: true
  validates :target, presence: true
  validates :source, uniqueness: { scope: :target_id, message: 'is already related' }
  validate :check_self_relation
  validate :check_opposite_relation

  scope :for_source_epic, ->(epic) { where(source_id: epic.id) }
  scope :for_target_epic, ->(epic) { where(target_id: epic.id) }

  TYPE_RELATES_TO = 'relates_to'
  TYPE_BLOCKS = 'blocks'
  TYPE_IS_BLOCKED_BY = 'is_blocked_by'

  enum link_type: { TYPE_RELATES_TO => 0, TYPE_BLOCKS => 1 }

  private

  def check_self_relation
    return unless source && target

    if source == target
      errors.add(:source, 'cannot be related to itself')
    end
  end

  def check_opposite_relation
    return unless source && target

    if Epic::RelatedEpicLink.find_by(source: target, target: source)
      errors.add(:source, 'is already related to this epic')
    end
  end
end
