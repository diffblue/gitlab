# frozen_string_literal: true

module Vulnerabilities
  class ScannerPresenter < Gitlab::View::Presenter::Delegated
    presents ::Vulnerabilities::Scanner, as: :scanner

    delegator_override :to_global_id
    def to_global_id
      ::Gitlab::GlobalId.build(scanner) if scanner.id
    end

    def report_type_humanized
      report_type = scanner.report_type
      case report_type&.to_sym
      when :dast, :sast then report_type.to_s.upcase
      when :api_fuzzing then 'API Fuzzing'
      else report_type.to_s.titleize
      end
    end
  end
end
