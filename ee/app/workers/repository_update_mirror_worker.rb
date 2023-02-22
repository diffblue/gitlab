# frozen_string_literal: true

class RepositoryUpdateMirrorWorker
  UpdateError = Class.new(StandardError)

  include ApplicationWorker

  idempotent!
  data_consistency :sticky
  include ProjectStartImport

  feature_category :source_code_management

  # Retry not necessary. It will try again at the next update interval.
  sidekiq_options retry: false, status_expiration: Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    project = Project
                .with_import_state
                .inc_routes
                .with_group
                .include_project_feature
                .find(project_id)

    @current_user = project.mirror_user || project.creator

    return unless start_mirror(project)

    result = Projects::UpdateMirrorService.new(project, @current_user).execute
    raise UpdateError, result[:message] if result[:status] == :error

    finish_mirror(project)
  rescue UpdateError => ex
    fail_mirror(project, ex.message)
    raise
  rescue StandardError => ex
    return unless project

    fail_mirror(project, ex.message)
    raise UpdateError, "#{ex.class}: #{ex.message}"
  end

  private

  def start_mirror(project)
    import_state = project.import_state

    if start(import_state)
      Gitlab::AppLogger.info(message: "Mirror update for #{project.full_path} started. Waiting duration: #{import_state.mirror_waiting_duration}", jid: jid)
      metric_mirror_waiting_duration_seconds.observe({}, import_state.mirror_waiting_duration)

      true
    else
      Gitlab::AppLogger.info(message: "Project #{project.full_path} was in inconsistent state: #{import_state.status}.", jid: jid)
      false
    end
  end

  def fail_mirror(project, message)
    project.import_state.mark_as_failed(message)
    Gitlab::AppLogger.error(message: "Mirror update for #{project.full_path} failed with the following message: #{message}.", jid: jid)
  end

  def finish_mirror(project)
    import_state = project.import_state
    import_state.finish

    Gitlab::AppLogger.info(message: "Mirror update for #{project.full_path} successfully finished. Update duration: #{import_state.mirror_update_duration}", jid: jid)
    metric_mirror_update_duration_seconds.observe({}, import_state.mirror_update_duration)
  end

  def metric_mirror_update_duration_seconds
    @metric_mirror_update_duration_seconds ||= Gitlab::Metrics.histogram(
      :gitlab_repository_mirror_update_duration_seconds,
      'Mirror update duration',
      {},
      [0.1, 1.0, 10.0, 30.0, 60.0, 120.0, 300.0, 600.0]
    )
  end

  def metric_mirror_waiting_duration_seconds
    @metric_mirror_waiting_duration_seconds ||= Gitlab::Metrics.histogram(
      :gitlab_repository_mirror_waiting_duration_seconds,
      'Waiting length for repository mirror',
      {},
      [1.0, 10.0, 30.0, 60.0, 300.0, 600.0, 1800.0, 2400.0, 3600.0]
    )
  end
end
