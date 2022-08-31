# frozen_string_literal: true
module EE
  # PostReceive EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `IssuableExportCsvWorker` worker
  module IssuableExportCsvWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override

    private

    override :export_service
    def export_service(type, user, project, params)
      return super unless [:requirement, :issue].include?(type.to_sym)

      issuable_classes = issuable_classes_for(type.to_sym)
      issuables = issuable_classes[:finder].new(user, parse_params(params, project.id)).execute

      if type.to_sym == :issue
        issuable_classes[:service].new(issuables, project, user)
      else
        fields = params.with_indifferent_access.delete(:selected_fields) || []
        issuable_classes[:service].new(issuables, project, fields)
      end
    end

    override :issuable_classes_for
    def issuable_classes_for(type)
      return super unless type.to_sym == :requirement

      {
        finder: ::RequirementsManagement::RequirementsFinder,
        service: ::RequirementsManagement::ExportCsvService
      }
    end

    override :type_error_message
    def type_error_message(type)
      "Type parameter must be :issue, :merge_request, or :requirements, it was #{type}"
    end
  end
end
