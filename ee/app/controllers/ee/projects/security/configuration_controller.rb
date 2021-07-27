# frozen_string_literal: true
module EE
  module Projects
    module Security
      module ConfigurationController
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          alias_method :vulnerable, :project

          before_action :ensure_security_dashboard_feature_enabled!, except: [:show]
          before_action :authorize_read_security_dashboard!, except: [:show]

          before_action only: [:show] do
            push_frontend_feature_flag(:security_auto_fix, project, default_enabled: false)
            push_frontend_feature_flag(:sec_dependency_scanning_ui_enable, project, default_enabled: :yaml)
          end

          before_action only: [:auto_fix] do
            check_feature_flag!
            authorize_modify_auto_fix_setting!
          end

          feature_category :static_application_security_testing

          before_action only: [:show] do
            push_frontend_feature_flag(:security_configuration_redesign_ee, project, default_enabled: :yaml)
          end
        end

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        override :show
        def show
          return super unless security_dashboard_feature_enabled? && can_read_security_dashboard?

          @configuration = ::Projects::Security::ConfigurationPresenter.new(project,
                                                                            auto_fix_permission: auto_fix_authorized?,
                                                                            current_user: current_user)
          respond_to do |format|
            format.html
            format.json do
              render status: :ok, json: @configuration.to_h
            end
          end
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        def auto_fix
          service = ::Security::Configuration::SaveAutoFixService.new(project, auto_fix_params[:feature])

          return respond_422 unless service.execute(enabled: auto_fix_params[:enabled])

          render status: :ok, json: auto_fix_settings
        end

        private

        def auto_fix_authorized?
          can?(current_user, :modify_auto_fix_setting, project)
        end

        def auto_fix_params
          @auto_fix_params ||= begin
            fix_params = params.permit(:feature, :enabled)
            feature = fix_params[:feature]
            fix_params[:feature] = feature.blank? ? 'all' : feature.to_s
            fix_params
          end
        end

        def check_auto_fix_permissions!
          render_403 unless auto_fix_authorized?
        end

        def check_feature_flag!
          render_404 if ::Feature.disabled?(:security_auto_fix, project)
        end

        def auto_fix_settings
          setting = project.security_setting

          {
            dependency_scanning: setting.auto_fix_dependency_scanning,
            container_scanning: setting.auto_fix_container_scanning
          }
        end

        def security_dashboard_feature_enabled?
          vulnerable.feature_available?(:security_dashboard)
        end

        def can_read_security_dashboard?
          can?(current_user, :read_project_security_dashboard, vulnerable)
        end

        def ensure_security_dashboard_feature_enabled!
          render_404 unless security_dashboard_feature_enabled?
        end

        def authorize_read_security_dashboard!
          render_403 unless can_read_security_dashboard?
        end
      end
    end
  end
end
