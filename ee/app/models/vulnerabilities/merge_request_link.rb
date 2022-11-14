# frozen_string_literal: true
module Vulnerabilities
  class MergeRequestLink < ApplicationRecord
    self.table_name = 'vulnerability_merge_request_links'

    belongs_to :vulnerability
    belongs_to :merge_request

    validates :vulnerability, :merge_request, presence: true
    validates :merge_request_id,
              uniqueness: { scope: :vulnerability_id, message: N_('is already linked to this vulnerability') }
  end
end
