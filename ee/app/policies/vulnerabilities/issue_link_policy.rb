# frozen_string_literal: true

module Vulnerabilities
  class IssueLinkPolicy < BasePolicy
    delegate { @subject.vulnerability&.project }

    condition(:issue_readable?) { @subject.issue&.readable_by?(@user) }

    rule { issue_readable? }.enable :read_issue_link
  end
end
