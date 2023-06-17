# frozen_string_literal: true

module Import
  class ValidateRepositorySizeService
    def initialize(project)
      @project = project
    end

    def execute
      return unless ::Feature.enabled?(:post_import_repository_size_check)

      project.repository.expire_content_cache

      ::Projects::UpdateStatisticsService.new(project, nil, statistics: [:repository_size]).execute

      return unless project.repository_size_checker.above_size_limit?

      ::Projects::RepositoryDestroyWorker.perform_async(project.id)

      raise ::Projects::ImportService::Error, s_("ImportProjects|Repository above permitted size limit.")
    end

    private

    attr_reader :project
  end
end
