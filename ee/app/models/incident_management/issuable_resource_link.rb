# frozen_string_literal: true

module IncidentManagement
  class IssuableResourceLink < ApplicationRecord
    DEFAULT_LINK_TYPE = 'general'

    self.table_name = 'issuable_resource_links'

    belongs_to :issue, inverse_of: :issuable_resource_links

    enum link_type: { general: 0, zoom: 1, slack: 2, pagerduty: 3 } # 'general' is the default type

    validates :issue, presence: true
    validates :link, presence: true, length: { maximum: 2200 }, addressable_url: { schemes: %w(http https) }
    validates :link_text, length: { maximum: 255 }

    scope :order_by_created_at_asc, -> { reorder(created_at: :asc) }
    scope :slack_links, -> { where(link_type: :slack) }
    scope :zoom_links, -> { where(link_type: :zoom) }
    scope :pagerduty_links, -> { where(link_type: :pagerduty) }
  end
end
