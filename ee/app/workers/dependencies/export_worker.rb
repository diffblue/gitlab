# frozen_string_literal: true

module Dependencies
  class ExportWorker
    include ApplicationWorker
    include ::Gitlab::ExclusiveLeaseHelpers

    LEASE_TTL = 1.hour
    LEASE_NAMESPACE = "dependencies_export_worker"

    data_consistency :always

    sidekiq_options retry: true

    idempotent!
    feature_category :dependency_management

    sidekiq_retries_exhausted do |job|
      Dependencies::DependencyListExport.find_by_id(job['args'].last).failed!
    end

    def perform(dependency_list_export_id)
      dependency_list_export = Dependencies::DependencyListExport.find(dependency_list_export_id)
      in_lock(lease_key(dependency_list_export_id), ttl: LEASE_TTL) do
        generate_file(dependency_list_export) if dependency_list_export.created?
      end
    end

    private

    def generate_file(dependency_list_export)
      dependency_list_export.start!
      dependencies = fetch_dependencies(dependency_list_export.project, dependency_list_export.author)
      Tempfile.open(['json']) do |file|
        file.write(::Gitlab::Json.dump(dependencies))
        dependency_list_export.file = file
      end
      dependency_list_export.file.filename = filename(dependency_list_export.project)
      dependency_list_export.finish!
    ensure
      Dependencies::DestroyExportWorker.perform_in(1.hour, dependency_list_export.id)
    end

    def fetch_dependencies(project, user)
      report_service = report_fetch_service(project)
      parameters = { request: EntityRequest.new({ project: project, user: user }), build: report_service.build }
      DependencyListEntity.represent(dependencies_list(report_service), parameters)
    end

    def report_fetch_service(project)
      job_artifacts = ::Ci::JobArtifact.of_report_type(:dependency_list)
      ::Security::ReportFetchService.new(project, job_artifacts)
    end

    def dependencies_list(report_service)
      return [] unless report_service.able_to_fetch?

      ::Security::DependencyListService.new(pipeline: report_service.pipeline).execute
    end

    def filename(project)
      [
        project.full_path.parameterize,
        '_dependencies_',
        Time.current.utc.strftime('%FT%H%M'),
        '.',
        'json'
      ].join
    end

    def lease_key(dependency_list_export_id)
      "#{LEASE_NAMESPACE}:#{dependency_list_export_id}"
    end
  end
end
