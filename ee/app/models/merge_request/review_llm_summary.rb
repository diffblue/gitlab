# rubocop:disable Style/ClassAndModuleChildren
# frozen_string_literal: true

class MergeRequest::ReviewLlmSummary < ApplicationRecord
  belongs_to :review
  belongs_to :merge_request_diff
  belongs_to :user, optional: true

  validates :provider, presence: true
  validates :content, presence: true, length: { maximum: 2056 }

  enum provider: { open_ai: 0, vertex_ai: 1 }

  scope :from_reviewer, ->(reviewer) { joins(:review).where(review: { author_id: reviewer.id }) }

  def reviewer
    review.author
  end
end
# rubocop:enable Style/ClassAndModuleChildren
