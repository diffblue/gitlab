# frozen_string_literal: true

module ComplianceManagement
  class UpdateDefaultFrameworkWorker
    include ApplicationWorker

    idempotent!
    data_consistency :always
    urgency :low
    feature_category :compliance_management

    def perform(user_id, project_id, compliance_framework_id)
      current_user = User.find(user_id)
      project = Project.find(project_id)

      ::Projects::UpdateService.new(
        project, current_user,
        compliance_framework_setting_attributes: { framework: compliance_framework_id }
      ).execute

    rescue ActiveRecord::RecordNotFound => e
      Gitlab::ErrorTracking.log_exception(e)
    end
  end
end
