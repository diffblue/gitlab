# frozen_string_literal: true

class Epic::RelatedEpicLink < ApplicationRecord
  include IssuableLink

  belongs_to :source, class_name: 'Epic'
  belongs_to :target, class_name: 'Epic'

  self.table_name = 'related_epic_links'

  class << self
    extend ::Gitlab::Utils::Override

    override :issuable_type
    def issuable_type
      :epic
    end
  end
end
