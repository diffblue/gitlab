# frozen_string_literal: true

class Epic::RelatedEpicLink < ApplicationRecord
  include IssuableLink
  include CreatedAtFilterable
  include UpdatedAtFilterable

  self.table_name = 'related_epic_links'

  belongs_to :source, class_name: 'Epic'
  belongs_to :target, class_name: 'Epic'

  scope :with_api_entity_associations, -> do
    preload(
      source: [:author, :labels, { group: [:saml_provider, :route] }],
      target: [:author, :labels, { group: [:saml_provider, :route] }]
    )
  end

  class << self
    extend ::Gitlab::Utils::Override

    override :issuable_type
    def issuable_type
      :epic
    end
  end
end
