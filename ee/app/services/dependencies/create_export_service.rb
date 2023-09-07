# frozen_string_literal: true

module Dependencies
  class CreateExportService
    attr_reader :author, :exportable, :export_type

    def initialize(exportable, author, export_type = 'dependency_list')
      @author = author
      @exportable = exportable
      @export_type = export_type
    end

    def execute
      dependency_list_export = Dependencies::DependencyListExport.create!(
        exportable: exportable,
        author: author,
        export_type: export_type
      )
      Dependencies::ExportWorker.perform_async(dependency_list_export.id)
      dependency_list_export
    rescue StandardError
      nil
    end
  end
end
