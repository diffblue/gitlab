# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module ChangesAccess
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :bulk_access_checks!
        def bulk_access_checks!
          super

          PushRuleCheck.new(self).validate!
        end
      end
    end
  end
end
