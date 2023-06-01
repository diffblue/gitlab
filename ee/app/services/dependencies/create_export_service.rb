# frozen_string_literal: true

module Dependencies
  class CreateExportService
    attr_reader :author, :exportable

    def initialize(exportable, author)
      @author = author
      @exportable = exportable
    end

    def execute
      dependency_list_export = Dependencies::DependencyListExport.create!(exportable: exportable, author: author)
      Dependencies::ExportWorker.perform_async(dependency_list_export.id)
      dependency_list_export
    rescue StandardError
      nil
    end
  end
end
