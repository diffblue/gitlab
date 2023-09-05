# frozen_string_literal: true

module EE
  module Issues
    module ImportCsvService
      extend ::Gitlab::Utils::Override

      override :perform_spam_check?
      def perform_spam_check?
        return false if user.belongs_to_paid_namespace?(exclude_trials: true)

        super
      end
    end
  end
end
