# frozen_string_literal: true

module EE
  module Spam
    module SpamVerdictService
      extend ::Gitlab::Utils::Override

      override :allow_possible_spam?
      def allow_possible_spam?
        return true if user.belongs_to_paid_namespace?(exclude_trials: true)

        super
      end
    end
  end
end
