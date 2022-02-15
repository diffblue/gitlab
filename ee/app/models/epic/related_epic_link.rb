# frozen_string_literal: true

class Epic::RelatedEpicLink < ApplicationRecord
  include IssuableLink

  belongs_to :source, class_name: 'Epic'
  belongs_to :target, class_name: 'Epic'

  self.table_name = 'related_epic_links'

  scope :for_source_epic, ->(epic) { where(source_id: epic.id) }
  scope :for_target_epic, ->(epic) { where(target_id: epic.id) }

  private

  def issuable_type
    :epic
  end
end
