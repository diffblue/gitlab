# frozen_string_literal: true

module Dependencies
  class FetchExportService
    attr_reader :dependency_list_export_id

    def initialize(dependency_list_export_id)
      @dependency_list_export_id = dependency_list_export_id
    end

    def execute
      Dependencies::DependencyListExport.find(dependency_list_export_id)
    rescue StandardError
      nil
    end
  end
end
