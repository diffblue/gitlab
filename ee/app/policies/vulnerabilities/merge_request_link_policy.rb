# frozen_string_literal: true

module Vulnerabilities
  class MergeRequestLinkPolicy < BasePolicy
    delegate { @subject.vulnerability&.project }

    condition(:merge_request_readable?) do
      Ability.allowed?(@user, :read_merge_request, @subject.merge_request)
    end

    rule { ~merge_request_readable? }.prevent :read_vulnerability_merge_request_link
  end
end
