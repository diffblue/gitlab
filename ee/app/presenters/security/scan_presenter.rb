# frozen_string_literal: true

module Security
  class ScanPresenter < Gitlab::View::Presenter::Delegated
    MESSAGE_FORMAT = '[%<type>s] %<message>s'

    presents ::Security::Scan, as: :scan

    delegator_override :errors
    def errors
      processing_errors.to_a.map { |error| format(MESSAGE_FORMAT, error.symbolize_keys) }
    end

    delegator_override :warnings
    def warnings
      processing_warnings.to_a.map { |warning| format(MESSAGE_FORMAT, warning.symbolize_keys) }
    end
  end
end
