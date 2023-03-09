# frozen_string_literal: true
module EE
  # PostReceive EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `IssuableExportCsvWorker` worker
  module IssuableExportCsvWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override

    private

    override :issuable_classes_for
    def issuable_classes_for(type)
      return super unless type.to_sym == :requirement

      {
        finder: ::WorkItems::WorkItemsFinder,
        service: ::RequirementsManagement::ExportCsvService
      }
    end

    override :parse_params
    def parse_params(params, project_id, type)
      return super unless type.to_sym == :requirement

      super.merge(issue_types: [:requirement])
    end

    override :allowed_types
    def allowed_types
      super.push(':requirement')
    end
  end
end
