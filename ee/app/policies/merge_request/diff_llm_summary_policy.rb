# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class MergeRequest::DiffLlmSummaryPolicy < BasePolicy
  delegate { @subject.merge_request_diff.project }
end
# rubocop:enable Style/ClassAndModuleChildren
