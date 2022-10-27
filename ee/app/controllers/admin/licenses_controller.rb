# frozen_string_literal: true

class Admin::LicensesController < Admin::ApplicationController
  include Admin::LicenseRequest

  before_action :license, only: [:download, :destroy]
  before_action :require_license, only: [:download, :destroy]

  respond_to :html

  feature_category :sm_provisioning
  urgency :low

  def create
    return upload_license_error if license_params[:data].blank? && license_params[:data_file].blank?

    @license = License.new(license_params)

    return upload_license_error(cloud_license: true) if @license.online_cloud_license?

    if @license.save
      notice = if @license.started?
                 _('The license was successfully uploaded and is now active. You can see the details below.')
               else
                 _('The license was successfully uploaded and will be active from %{starts_at}. You can see the details below.' % { starts_at: @license.starts_at })
               end

      flash[:notice] = notice
      redirect_to(admin_subscription_path)
    else
      flash[:alert] = @license.errors.full_messages.join.html_safe
      redirect_to general_admin_application_settings_path
    end
  end

  def destroy
    Licenses::DestroyService.new(license, current_user).execute

    respond_to do |format|
      format.json do
        if License.current
          flash[:notice] = _('The license was removed. GitLab has fallen back on the previous license.')
        else
          flash[:alert] = _('The license was removed. GitLab now no longer has a valid license.')
        end

        render json: { success: true }
      end
    end
  end

  def sync_seat_link
    respond_to do |format|
      format.json do
        if Gitlab::SeatLinkData.new.sync
          render json: { success: true }
        else
          render json: { success: false }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def license_params
    license_params = params.require(:license).permit(:data_file, :data)
    license_params.delete(:data) if license_params[:data_file]
    license_params
  end

  def upload_license_error(cloud_license: false)
    flash[:alert] = if cloud_license
                      html_escape(
                        _(
                          "It looks like you're attempting to activate your subscription. Use " \
                            "%{a_start}the Subscription page%{a_end} instead."
                        )
                      ) % { a_start: "<a href=\"#{admin_subscription_path}\">".html_safe, a_end: '</a>'.html_safe }
                    else
                      html_escape(
                        _('The license you uploaded is invalid. If the issue persists, contact support at %{link}.')
                      ) % { link: '<a href="https://support.gitlab.com">https://support.gitlab.com</a>'.html_safe }
                    end

    @license = License.new
    redirect_to general_admin_application_settings_path
  end
end
