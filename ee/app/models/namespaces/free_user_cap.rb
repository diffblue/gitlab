# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    FREE_USER_LIMIT = 5

    def self.trimming_enabled?
      ::Feature.enabled?(:free_user_cap_data_remediation_job)
    end

    def self.group_sharing_remediation_enabled?
      ::Feature.enabled?(:free_user_cap_group_sharing_remediation)
    end
  end
end
