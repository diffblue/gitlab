# frozen_string_literal: true

module RequirementsManagement
  class ExportCsvService < ExportCsv::BaseService
    def initialize(relation, resource_parent, fields = [])
      super(relation, resource_parent)

      @fields = fields
    end

    def email(user)
      Notify.requirements_csv_email(user, resource_parent, csv_data, csv_builder.status).deliver_now
    end

    private

    def associations_to_preload
      [{ requirement: :recent_test_reports }, :author]
    end

    def header_to_value_hash
      RequirementsManagement::MapExportFieldsService.new(@fields).execute
    end
  end
end
