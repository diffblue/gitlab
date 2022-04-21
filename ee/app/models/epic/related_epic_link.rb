# frozen_string_literal: true

class Epic::RelatedEpicLink < ApplicationRecord
  include IssuableLink

  self.table_name = 'related_epic_links'

  MAX_EPIC_RELATIONS = 100

  belongs_to :source, class_name: 'Epic'
  belongs_to :target, class_name: 'Epic'

  validate :validate_max_epic_relations, on: :create

  class << self
    extend ::Gitlab::Utils::Override

    override :issuable_type
    def issuable_type
      :epic
    end
  end

  private

  def validate_max_epic_relations
    if source && source.unauthorized_related_epics.count >= MAX_EPIC_RELATIONS
      errors.add :source, _('This epic would exceed maximum number of related epics.')
    end

    if target && target.unauthorized_related_epics.count >= MAX_EPIC_RELATIONS
      errors.add :target, _('This epic would exceed maximum number of related epics.')
    end
  end
end
