# frozen_string_literal: true

module MergeRequests
  class StatusCheckResponse < ApplicationRecord
    self.table_name = 'status_check_responses'

    include ShaAttribute

    sha_attribute :sha

    belongs_to :merge_request
    belongs_to :external_status_check, class_name: 'MergeRequests::ExternalStatusCheck'

    enum status: %w(passed failed)

    validates :merge_request, presence: true
    validates :external_status_check, presence: true
    validates :sha, presence: true
  end
end

::MergeRequests::StatusCheckResponse.prepend_mod
