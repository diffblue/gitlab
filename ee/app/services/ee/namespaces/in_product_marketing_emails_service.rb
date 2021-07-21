# frozen_string_literal: true

module EE
  module Namespaces
    module InProductMarketingEmailsService
      extend ::Gitlab::Utils::Override

      private

      override :subscription_scope
      def subscription_scope
        ::Namespace.not_in_active_trial.in_default_plan
      end
    end
  end
end
