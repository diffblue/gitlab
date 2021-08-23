# frozen_string_literal: true

module StatusPage
  # Corresponds to an issue which has been published to the Status Page.
  class PublishedIncident < ApplicationRecord
    self.table_name = "status_page_published_incidents"

    belongs_to :issue, inverse_of: :status_page_published_incident
    validates :issue, presence: true

    # NOTE: This method is not atomic and might raise
    # +ActiveRecord::RecordNotUnique+ in case of a duplicate published issue.
    #
    # Previously, we've used +safe_find_or_create_by+ to circumvent this fact
    # but it uses subtransactions under the hood which is problematic in nested
    # transactions.
    #
    # See https://gitlab.com/groups/gitlab-org/-/epics/6540 for more context.
    #
    # In the rare event of +ActiveRecord::RecordNotUnique+ users end up seeing
    # a meaningful error message. This behaviour is acceptable and that's why
    # switched to unsafe method +find_or_create_by+.
    #
    # @raise ActiveRecord::RecordNotUnique
    def self.track(issue)
      find_or_create_by!(issue: issue)
    end

    def self.untrack(issue)
      find_by(issue: issue)&.destroy
    end
  end
end
