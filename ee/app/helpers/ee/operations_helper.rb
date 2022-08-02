# frozen_string_literal: true

module EE
  module OperationsHelper
    extend ::Gitlab::Utils::Override

    def operations_data
      {
        'add-path' => add_operations_project_path(format: :json),
        'list-path' => operations_path(format: :json),
        'empty-dashboard-svg-path' => image_path('illustrations/operations-dashboard_empty.svg'),
        'empty-dashboard-help-path' => help_page_path('user/operations_dashboard/index.md'),
        'operations-dashboard-help-path' => help_page_path('user/operations_dashboard/index.md')
      }
    end

    def environments_data
      {
        'add-path' => add_operations_environments_project_path(format: :json),
        'list-path' => operations_environments_path(format: :json),
        'empty-dashboard-svg-path' => image_path('illustrations/operations-dashboard_empty.svg'),
        'empty-dashboard-help-path' => help_page_path('ci/environments/environments_dashboard.md'),
        'environments-dashboard-help-path' => help_page_path('ci/environments/environments_dashboard.md')
      }
    end

    def status_page_settings_data
      {
        'operations-settings-endpoint' => project_settings_operations_path(@project),
        'enabled' => status_page_setting.enabled?.to_s,
        'url' => status_page_setting&.status_page_url,
        'bucket-name' => status_page_setting.aws_s3_bucket_name,
        'region' => status_page_setting.aws_region,
        'aws-access-key' => status_page_setting.aws_access_key,
        'aws-secret-key' => status_page_setting.masked_aws_secret_key
      }
    end

    override :alerts_settings_data
    def alerts_settings_data(disabled: false)
      super.merge(alert_management_multiple_integrations_data, alert_fields)
    end

    override :operations_settings_data
    def operations_settings_data
      super.merge(incident_sla_data)
    end

    private

    def incident_sla_data
      setting = project_incident_management_setting

      {
        sla_feature_available: sla_feature_available?.to_s,
        sla_active: setting.sla_timer.to_s,
        sla_minutes: setting.sla_timer_minutes
      }
    end

    def sla_feature_available?
      ::IncidentManagement::IncidentSla.available_for?(@project)
    end

    def alert_management_multiple_integrations_data
      {
        'multi_integrations' => @project.feature_available?(:multiple_alert_http_integrations).to_s
      }
    end

    def alert_fields
      return {} unless ::Gitlab::AlertManagement.custom_mapping_available?(@project)

      {
        'alert_fields' => ::Gitlab::AlertManagement.alert_fields.map { |f| f.slice(:name, :label, :types) }.to_json
      }
    end
  end
end
