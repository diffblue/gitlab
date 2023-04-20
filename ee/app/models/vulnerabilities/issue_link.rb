# frozen_string_literal: true

module Vulnerabilities
  class IssueLink < ApplicationRecord
    self.table_name = 'vulnerability_issue_links'

    belongs_to :vulnerability
    belongs_to :issue

    has_one :author, through: :issue, class_name: 'User'

    enum link_type: { related: 1, created: 2 } # 'related' is the default value

    validates :vulnerability, :issue, presence: true
    validates :issue_id, uniqueness: { scope: :vulnerability_id, message: N_('has already been linked to another vulnerability') }
    validates :vulnerability_id,
              uniqueness: {
                conditions: -> { where(link_type: 'created') },
                message: N_('already has a "created" issue link')
              },
              if: :created?

    scope :by_link_type, -> (link_type) { link_type ? where(link_type: link_type.downcase) : all }
    scope :for_issue, -> (issue) { where(issue_id: issue) }
    scope :with_associations, -> { preload(:issue, vulnerability: [:project]) }
    scope :with_issues, -> { includes(:issue) }
  end
end
