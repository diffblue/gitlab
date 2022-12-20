# frozen_string_literal: true

module EE
  module ApplicationHelper
    extend ::Gitlab::Utils::Override

    DB_LAG_SHOW_THRESHOLD = 60 # seconds
    LOG_CURSOR_CHECK_TIME = ::Gitlab::Geo::LogCursor::Daemon::SECONDARY_CHECK_INTERVAL
    EVENT_PROCESSING_TIME = 60.seconds
    EVENT_LAG_SHOW_THRESHOLD = DB_LAG_SHOW_THRESHOLD.seconds + LOG_CURSOR_CHECK_TIME + EVENT_PROCESSING_TIME

    override :read_only_message
    def read_only_message
      return custom_maintenance_mode_message if ::Gitlab.maintenance_mode?

      return super unless ::Gitlab::Geo.secondary?
    end

    def read_only_description
      s_('You are on a read-only GitLab instance.') if ::Gitlab.maintenance_mode? && !::Gitlab::Geo.secondary?
    end

    def geo_secondary_read_only_description
      return unless ::Gitlab::Geo.secondary?

      message = @limited_actions_message ? s_('Geo|You may be able to make a limited amount of changes or perform a limited amount of actions on this page.') : s_('Geo|If you want to make changes, you must visit the primary site.')

      message = "#{message} #{lag_message}".html_safe if lag_message

      tag.span do
        concat(s_('Geo|You are on a secondary, %{b_open}read-only%{b_close} Geo site.').html_safe % { b_open: '<b>'.html_safe, b_close: '</b>'.html_safe })
        concat(" #{message}")
      end
    end

    def lag_message
      if db_lag > DB_LAG_SHOW_THRESHOLD
        return (s_('Geo|The database is currently %{db_lag} behind the primary site.') %
          { db_lag: time_ago_in_words(db_lag.seconds.ago) }).html_safe
      end

      if unprocessed_too_old?
        minutes_behind = time_ago_in_words(next_unprocessed_event.created_at)
        (s_('Geo|The site is currently %{minutes_behind} behind the primary site.') %
          { minutes_behind: minutes_behind }).html_safe
      end
    end

    def render_ce(partial, locals = {})
      render template: find_ce_template(partial), locals: locals
    end

    # Tries to find a matching partial first, if there is none, we try to find a matching view
    # rubocop: disable CodeReuse/ActiveRecord
    def find_ce_template(name)
      prefixes = [] # So don't create extra [] garbage

      if ce_lookup_context.exists?(name, prefixes, true)
        ce_lookup_context.find(name, prefixes, true)
      else
        ce_lookup_context.find(name, prefixes, false)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def ce_lookup_context
      @ce_lookup_context ||= begin
        ce_view_paths = lookup_context.view_paths.paths.reject do |resolver|
          resolver.to_path.start_with?("#{Rails.root}/ee")
        end

        ActionView::LookupContext.new(ce_view_paths)
      end
    end

    def smartcard_config_port
      ::Gitlab.config.smartcard.client_certificate_required_port
    end

    override :autocomplete_data_sources
    def autocomplete_data_sources(object, noteable_type)
      return {} unless object && noteable_type

      enabled_for_vulnerabilities = object.feature_available?(:security_dashboard)

      if object.is_a?(Group)
        {
          epics: epics_group_autocomplete_sources_path(object),
          iterations: object.feature_available?(:iterations) ? iterations_group_autocomplete_sources_path(object) : nil,
          vulnerabilities: enabled_for_vulnerabilities ? vulnerabilities_group_autocomplete_sources_path(object) : nil
        }.compact.merge(super)
      else
        {
          epics: object.group&.feature_available?(:epics) ? epics_project_autocomplete_sources_path(object) : nil,
          iterations: object.group&.feature_available?(:iterations) ? iterations_project_autocomplete_sources_path(object) : nil,
          vulnerabilities: enabled_for_vulnerabilities ? vulnerabilities_project_autocomplete_sources_path(object) : nil
        }.compact.merge(super)
      end
    end

    override :show_last_push_widget?
    def show_last_push_widget?(event)
      show = super
      project = event.project

      # Skip if this was a mirror update
      return false if project.mirror? && project.repository.up_to_date_with_upstream?(event.branch_name)

      show
    end

    private

    def custom_maintenance_mode_message
      ::Gitlab::CurrentSettings.maintenance_mode_message&.html_safe ||
        _('GitLab is undergoing maintenance')
    end

    def db_lag
      @db_lag ||= Rails.cache.fetch('geo:db_lag', expires_in: 20.seconds) do
        ::Gitlab::Geo::HealthCheck.new.db_replication_lag_seconds
      end
    end

    def next_unprocessed_event
      @next_unprocessed_event ||= ::Geo::EventLog.next_unprocessed_event
    end

    def unprocessed_too_old?
      Rails.cache.fetch('geo:unprocessed_too_old', expires_in: 20.seconds) do
        break false unless next_unprocessed_event

        next_unprocessed_event.created_at < EVENT_LAG_SHOW_THRESHOLD.ago
      end
    end
  end
end
