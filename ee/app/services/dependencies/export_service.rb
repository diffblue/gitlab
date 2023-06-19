# frozen_string_literal: true

module Dependencies
  class ExportService
    SERIALIZER_SERVICES = {
      Project => ExportSerializers::ProjectDependenciesService,
      Group => ExportSerializers::GroupDependenciesService
    }.freeze

    def self.execute(dependency_list_export)
      new(dependency_list_export).execute
    end

    def initialize(dependency_list_export)
      @dependency_list_export = dependency_list_export
    end

    def execute
      return unless dependency_list_export.created?

      create_export
      schedule_export_deletion
    end

    private

    attr_reader :dependency_list_export

    delegate :exportable, to: :dependency_list_export, private: true

    def create_export
      dependency_list_export.start!

      create_export_file

      dependency_list_export.finish!
    rescue StandardError
      dependency_list_export.reset_state!

      raise
    end

    def create_export_file
      Tempfile.open('json') do |file|
        file.write(file_content)

        dependency_list_export.file = file
        dependency_list_export.file.filename = filename
      end
    end

    def file_content
      ::Gitlab::Json.dump(dependencies)
    end

    def dependencies
      serializer_service.execute(dependency_list_export)
    end

    def serializer_service
      SERIALIZER_SERVICES.fetch(exportable.class)
    end

    def filename
      [
        exportable.full_path.parameterize,
        '_dependencies_',
        Time.current.utc.strftime('%FT%H%M'),
        '.',
        'json'
      ].join
    end

    def schedule_export_deletion
      Dependencies::DestroyExportWorker.perform_in(1.hour, dependency_list_export.id)
    end
  end
end
