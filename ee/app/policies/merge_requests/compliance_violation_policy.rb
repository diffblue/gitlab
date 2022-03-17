# frozen_string_literal: true

module MergeRequests
  class ComplianceViolationPolicy < BasePolicy
    delegate { @subject.merge_request.target_project.namespace }
  end
end
