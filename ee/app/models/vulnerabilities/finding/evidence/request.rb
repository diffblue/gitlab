# frozen_string_literal: true

module Vulnerabilities
  class Finding
    class Evidence
      class Request < ApplicationRecord
        include WithBody

        self.table_name = 'vulnerability_finding_evidence_requests'

        belongs_to :evidence,
                   class_name: 'Vulnerabilities::Finding::Evidence',
                   inverse_of: :request,
                   foreign_key: 'vulnerability_finding_evidence_id'
        belongs_to :supporting_message,
                   class_name: 'Vulnerabilities::Finding::Evidence::SupportingMessage',
                   inverse_of: :request,
                   foreign_key: 'vulnerability_finding_evidence_supporting_message_id'

        has_many :headers,
                 class_name: 'Vulnerabilities::Finding::Evidence::Header',
                 inverse_of: :request,
                 foreign_key: 'vulnerability_finding_evidence_request_id'

        validates :method, length: { maximum: 32 }
        validates :url, length: { maximum: 2048 }
      end
    end
  end
end
