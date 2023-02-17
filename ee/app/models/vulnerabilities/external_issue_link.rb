# frozen_string_literal: true

module Vulnerabilities
  class ExternalIssueLink < ApplicationRecord
    include EachBatch

    self.table_name = 'vulnerability_external_issue_links'

    belongs_to :author, class_name: 'User'
    belongs_to :vulnerability

    declarative_enum LinkTypeEnum
    declarative_enum ExternalTypeEnum

    validates :vulnerability, :external_issue_key, :external_type, :external_project_key, presence: true
    validates :external_issue_key, uniqueness: { scope: [:vulnerability_id, :external_type, :external_project_key], message: N_('has already been linked to another vulnerability') }
    validates :vulnerability_id,
              uniqueness: {
                conditions: -> { where(link_type: 'created') },
                message: N_('already has a "created" issue link')
              },
              if: :created?

    scope :created_for_vulnerability, -> (vulnerability) { where(vulnerability: vulnerability, link_type: 'created') }
  end
end
