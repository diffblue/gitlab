# frozen_string_literal: true

module MicrosoftApplicationActions
  extend ActiveSupport::Concern
  include SafeFormatHelper

  included do
    feature_category :system_access, [:update_microsoft_application]

    before_action :check_microsoft_group_sync_available, only: [:update_microsoft_application]
  end

  def update_microsoft_application
    application = ::SystemAccess::MicrosoftApplication.find_or_initialize_by(namespace: microsoft_application_namespace) # rubocop:disable CodeReuse/ActiveRecord

    params = microsoft_application_params.dup
    params.delete(:client_secret) if params[:client_secret].blank?

    if application.update(params)
      flash[:notice] = s_('Microsoft|Microsoft Azure integration settings were successfully updated.')
    else
      flash[:alert] = safe_format(
        s_('Microsoft|Microsoft Azure integration settings failed to save. %{errors}'),
        errors: application.errors.full_messages.to_sentence
      )
    end

    redirect_to microsoft_application_redirect_path
  end

  private

  def find_or_initialize_microsoft_application
    return unless microsoft_group_sync_enabled?

    @microsoft_application = # rubocop:disable Gitlab/ModuleWithInstanceVariables
      ::SystemAccess::MicrosoftApplication.find_or_initialize_by(namespace: microsoft_application_namespace) # rubocop:disable CodeReuse/ActiveRecord
  end

  def check_microsoft_group_sync_available
    render_404 unless microsoft_group_sync_enabled?
  end

  def microsoft_application_params
    params.require(:system_access_microsoft_application)
          .permit(:enabled, :tenant_xid, :client_xid, :client_secret, :login_endpoint, :graph_endpoint)
  end
end
