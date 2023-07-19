# rubocop:disable Style/ClassAndModuleChildren
# frozen_string_literal: true

class MergeRequest::DiffLlmSummary < ApplicationRecord
  belongs_to :merge_request_diff
  belongs_to :user, optional: true

  validates :merge_request_diff_id, uniqueness: true
  validates :provider, presence: true
  validates :content, presence: true, length: { maximum: 2056 }

  enum provider: { open_ai: 0, vertex_ai: 1 }
end
# rubocop:enable Style/ClassAndModuleChildren

# Added for JiHu
MergeRequest::DiffLlmSummary.prepend_mod
