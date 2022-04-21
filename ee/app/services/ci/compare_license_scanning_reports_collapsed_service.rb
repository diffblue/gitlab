# frozen_string_literal: true

module Ci
  class CompareLicenseScanningReportsCollapsedService < ::Ci::CompareLicenseScanningReportsService
    def serializer_class
      ::LicenseCompliance::CollapsedComparerSerializer
    end
  end
end
