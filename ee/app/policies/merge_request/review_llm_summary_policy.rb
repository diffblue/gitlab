# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class MergeRequest::ReviewLlmSummaryPolicy < BasePolicy
  delegate { @subject.merge_request_diff.project }
end
# rubocop:enable Style/ClassAndModuleChildren
