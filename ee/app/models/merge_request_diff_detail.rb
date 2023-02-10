# frozen_string_literal: true

class MergeRequestDiffDetail < ApplicationRecord
  include ::Geo::VerificationStateDefinition

  self.primary_key = :merge_request_diff_id

  belongs_to :merge_request_diff, inverse_of: :merge_request_diff_detail
end
