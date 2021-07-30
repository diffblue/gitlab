# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence
      class Header < ApplicationRecord
        self.table_name = 'vulnerability_finding_evidence_headers'

        belongs_to :request, class_name: 'Vulnerabilities::Finding::Evidence::Request', inverse_of: :headers, foreign_key: 'vulnerability_finding_evidence_request_id'
        belongs_to :response, class_name: 'Vulnerabilities::Finding::Evidence::Response', inverse_of: :headers, foreign_key: 'vulnerability_finding_evidence_response_id'

        validates :name, length: { maximum: 255 }, presence: true
        validates :value, length: { maximum: 8192 }, presence: true
        validate :request_or_response_is_set
        validate :request_and_response_cannot_be_set

        private

        def request_or_response_is_set
          errors.add(:header, _('Header must be associated with a request or response')) unless request.present? || response.present?
        end

        def request_and_response_cannot_be_set
          errors.add(:header, _('Header cannot be associated with both a request and a response')) if request.present? && response.present?
        end
      end
    end
  end
end
