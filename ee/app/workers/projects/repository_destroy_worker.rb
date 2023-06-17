# frozen_string_literal: true

module Projects
  class RepositoryDestroyWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :importers
    idempotent!

    def perform(project_id)
      project = ::Project.find_by_id(project_id)
      return unless project

      ::Repositories::DestroyService.new(project.repository).execute

      # Because the repository is destroyed inside a run_after_commit callback, we need to trigger the callback
      project.touch
    end
  end
end
