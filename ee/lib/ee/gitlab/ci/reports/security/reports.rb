# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Reports
        module Security
          module Reports
            include ::Gitlab::Ci::Reports::Security::Concerns::ScanFinding
            extend ActiveSupport::Concern
          end
        end
      end
    end
  end
end
