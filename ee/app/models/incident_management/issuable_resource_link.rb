# frozen_string_literal: true

module IncidentManagement
  class IssuableResourceLink < ApplicationRecord
    self.table_name = 'issuable_resource_links'

    belongs_to :incident, class_name: 'Issue', inverse_of: :issuable_resource_links

    enum link_type: { general: 0, zoom: 1, slack: 2 } # 'general' is the default type

    validates :issue, presence: true
    validates :link, presence: true, length: { maximum: 2200 }
    validates :link_text, length: { maximum: 255 }
  end
end
