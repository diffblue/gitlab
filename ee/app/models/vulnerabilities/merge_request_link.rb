# frozen_string_literal: true
module Vulnerabilities
  class MergeRequestLink < ApplicationRecord
    self.table_name = 'vulnerability_merge_request_links'

    belongs_to :vulnerability
    belongs_to :merge_request

    has_one :author, -> {
      allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422085')
    }, through: :merge_request, class_name: 'User'

    validates :vulnerability, :merge_request, presence: true
    validates :merge_request_id,
      uniqueness: { scope: :vulnerability_id, message: N_('is already linked to this vulnerability') }

    scope :by_finding_uuids, ->(uuids) do
      joins(vulnerability: [:findings]).where(vulnerability: {
        vulnerability_occurrences: { uuid: uuids }
      })
    end
    scope :with_vulnerability_findings, -> { includes(vulnerability: [:findings]) }
    scope :with_merge_request, -> { includes(:merge_request) }
  end
end
