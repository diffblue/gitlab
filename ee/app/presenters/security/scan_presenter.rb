# frozen_string_literal: true

module Security
  class ScanPresenter < Gitlab::View::Presenter::Delegated
    ERROR_MESSAGE_FORMAT = '[%<type>s] %<message>s'

    presents ::Security::Scan, as: :scan

    delegator_override :errors
    def errors
      processing_errors.to_a.map { |error| format(ERROR_MESSAGE_FORMAT, error.symbolize_keys) }
    end
  end
end
