# frozen_string_literal: true

class Epic::RelatedEpicLink < ApplicationRecord
  include IssuableLink

  belongs_to :source, class_name: 'Epic'
  belongs_to :target, class_name: 'Epic'

  self.table_name = 'related_epic_links'

  private

  def issuable_type
    :epic
  end
end
