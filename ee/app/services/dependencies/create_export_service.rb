# frozen_string_literal: true

module Dependencies
  class CreateExportService
    attr_reader :author, :project

    def initialize(project, author)
      @author = author
      @project = project
    end

    def execute
      dependency_list_export = Dependencies::DependencyListExport.create!(project: project, author: author)
      Dependencies::ExportWorker.perform_async(dependency_list_export.id)
      dependency_list_export
    rescue StandardError
      nil
    end
  end
end
