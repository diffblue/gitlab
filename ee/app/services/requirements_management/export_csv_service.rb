# frozen_string_literal: true

module RequirementsManagement
  class ExportCsvService < ::Issuable::ExportCsv::BaseService
    def initialize(issuables_relation, project, fields = [])
      super(issuables_relation, project)

      @fields = fields
    end

    def email(user)
      Notify.requirements_csv_email(user, project, csv_data, csv_builder.status).deliver_now
    end

    private

    def associations_to_preload
      [{ requirement_issue: :author }, :test_reports]
    end

    def header_to_value_hash
      RequirementsManagement::MapExportFieldsService.new(@fields).execute
    end
  end
end
