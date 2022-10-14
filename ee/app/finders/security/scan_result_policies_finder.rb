# frozen_string_literal: true

module Security
  class ScanResultPoliciesFinder < ScanPolicyBaseFinder
    def initialize(actor, object, params = {})
      super(actor, object, :scan_result_policies, params)
    end

    def execute
      fetch_scan_policies
    end
  end
end
