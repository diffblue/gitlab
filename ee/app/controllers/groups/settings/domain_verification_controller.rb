# frozen_string_literal: true

module Groups
  module Settings
    class DomainVerificationController < Groups::ApplicationController
      layout 'group_settings'

      before_action :check_feature_availability
      before_action :authorize_admin_group!
      before_action :check_operation_feature_flag, except: [:index]
      before_action :set_domain, except: [:index, :new, :create]

      feature_category :system_access
      urgency :low

      helper_method :domain_presenter

      def index
        @hide_search_settings = true
        @domains = group.all_projects_pages_domains(only_verified: false)
      end

      def new
        @domain = PagesDomain.new
      end

      def create
        @project = find_domain_project(create_params[:project_id])

        if @project.blank?
          @domain = PagesDomain.new(create_params)
          @domain.errors.add(:project_id, _('must be specified'))
          render 'new', status: :bad_request
        else
          @domain = PagesDomains::CreateService.new(@project, current_user, create_params).execute

          if @domain&.persisted?
            redirect_to group_settings_domain_verification_path(@group, @domain),
              status: :found,
              notice: s_('DomainVerification|Domain was added')
          else
            render 'new', status: :bad_request
          end
        end
      end

      def show; end

      def update
        service = ::PagesDomains::UpdateService.new(@domain.project, current_user, update_params)

        if service.execute(@domain)
          redirect_to group_settings_domain_verification_index_path(@group),
            status: :found,
            notice: s_('DomainVerification|Domain was updated')
        else
          render 'show', status: :bad_request
        end
      end

      def destroy
        PagesDomains::DeleteService.new(@domain.project, current_user).execute(@domain)

        respond_to do |format|
          format.html do
            redirect_to group_settings_domain_verification_index_path(@group),
              status: :found,
              notice: s_('DomainVerification|Domain was removed')
          end
          format.js
        end
      end

      def verify
        result = VerifyPagesDomainService.new(@domain).execute

        if result[:status] == :success
          flash[:notice] = s_('DomainVerification|Successfully verified domain ownership')
        else
          flash[:alert] = s_('DomainVerification|Failed to verify domain ownership')
        end

        redirect_to group_settings_domain_verification_path(@group, @domain)
      end

      def retry_auto_ssl
        PagesDomains::RetryAcmeOrderService.new(@domain).execute

        redirect_to group_settings_domain_verification_path(@group, @domain)
      end

      def clean_certificate
        update_params = { user_provided_certificate: nil, user_provided_key: nil }
        service = ::PagesDomains::UpdateService.new(@domain.project, current_user, update_params)

        flash[:alert] = @domain.errors.full_messages.join(', ') unless service.execute(@domain)

        redirect_to group_settings_domain_verification_path(@group, @domain)
      end

      private

      def check_feature_availability
        render_404 unless group.domain_verification_available?
      end

      def check_operation_feature_flag
        render_404 unless Feature.enabled?(:domain_verification_operation, @group)
      end

      def domain_presenter
        @domain_presenter ||= @domain.present(current_user: current_user)
      end

      def find_domain_project(project_id)
        projects = ::GroupProjectsFinder.new(
          group: group,
          current_user: current_user,
          options: { only_owned: true, include_subgroups: true }
        ).execute
        projects.find_by_id(project_id)
      end

      def create_params
        @create_params ||= params.require(:pages_domain).permit(:user_provided_key, :user_provided_certificate,
          :domain, :project_id, :auto_ssl_enabled)
      end

      def update_params
        params.fetch(:pages_domain, {}).permit(:user_provided_key, :user_provided_certificate, :auto_ssl_enabled)
      end

      def set_domain
        @domain ||= group.all_projects_pages_domains(only_verified: false).find_by_domain!(params[:id].to_s)
      end
    end
  end
end
