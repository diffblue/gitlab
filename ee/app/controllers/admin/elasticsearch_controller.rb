# frozen_string_literal: true

class Admin::ElasticsearchController < Admin::ApplicationController
  feature_category :global_search
  urgency :low

  # POST
  # Scheduling indexing jobs
  def enqueue_index
    if Gitlab::Elastic::Helper.default.index_exists?
      ::Elastic::IndexProjectsService.new.execute

      notice = _('Elasticsearch indexing started')
      queue_link = helpers.link_to(_('(check progress)'), sidekiq_path + '/queues/elastic_commit_indexer')
      flash[:notice] = "#{notice} #{queue_link}".html_safe
    else
      flash[:warning] = _('Please create an index before enabling indexing')
    end

    redirect_to redirect_path
  end

  # POST
  # Trigger reindexing task
  def trigger_reindexing
    if Elastic::ReindexingTask.running?
      flash[:warning] = _('Elasticsearch reindexing is already in progress')
    else
      @elasticsearch_reindexing_task = Elastic::ReindexingTask.new(trigger_reindexing_params)
      if @elasticsearch_reindexing_task.save
        flash[:notice] = _('Elasticsearch reindexing triggered')
      else
        errors = @elasticsearch_reindexing_task.errors.full_messages.join(', ')
        flash[:alert] = _("Elasticsearch reindexing was not started: %{errors}") % { errors: errors }
      end
    end

    redirect_to redirect_path(anchor: 'js-elasticsearch-reindexing')
  end

  # POST
  # Cancel index deletion after a successful reindexing operation
  def cancel_index_deletion
    task = Elastic::ReindexingTask.find(params[:task_id])
    task.update!(delete_original_index_at: nil)

    flash[:notice] = _('Index deletion is canceled')

    redirect_to redirect_path(anchor: 'js-elasticsearch-reindexing')
  end

  # POST
  # Retry a halted migration
  def retry_migration
    migration = Elastic::DataMigrationService[params[:version].to_i]

    Gitlab::Elastic::Helper.default.delete_migration_record(migration)
    Elastic::DataMigrationService.drop_migration_halted_cache!(migration)

    flash[:notice] = _('Migration has been scheduled to be retried')

    redirect_to redirect_path
  end

  private

  def redirect_path(anchor: 'js-elasticsearch-settings')
    advanced_search_admin_application_settings_path(anchor: anchor)
  end

  def trigger_reindexing_params
    permitted_params = params.require(:elastic_reindexing_task).permit(:elasticsearch_max_slices_running, :elasticsearch_slice_multiplier)
    trigger_reindexing_params = {}
    trigger_reindexing_params[:max_slices_running] = permitted_params[:elasticsearch_max_slices_running] if permitted_params.has_key?(:elasticsearch_max_slices_running)
    trigger_reindexing_params[:slice_multiplier] = permitted_params[:elasticsearch_slice_multiplier] if permitted_params.has_key?(:elasticsearch_slice_multiplier)

    trigger_reindexing_params
  end
end
