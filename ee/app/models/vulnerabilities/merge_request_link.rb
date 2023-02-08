# frozen_string_literal: true
module Vulnerabilities
  class MergeRequestLink < ApplicationRecord
    self.table_name = 'vulnerability_merge_request_links'

    belongs_to :vulnerability
    belongs_to :merge_request

    has_one :author, through: :merge_request, class_name: 'User'

    validates :vulnerability, :merge_request, presence: true
    validates :merge_request_id,
              uniqueness: { scope: :vulnerability_id, message: N_('is already linked to this vulnerability') }
  end
end
