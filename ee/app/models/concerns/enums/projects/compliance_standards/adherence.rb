# frozen_string_literal: true

module Enums
  module Projects
    module ComplianceStandards
      module Adherence
        def self.status
          { success: 0, fail: 1 }.freeze
        end

        def self.check_name
          {
            ComplianceManagement::Standards::Gitlab::PreventApprovalByAuthorService::CHECK_NAME => 0,
            ComplianceManagement::Standards::Gitlab::PreventApprovalByCommitterService::CHECK_NAME => 1
          }
        end

        def self.standard
          { ComplianceManagement::Standards::Gitlab::BaseService::STANDARD => 0 }
        end
      end
    end
  end
end
