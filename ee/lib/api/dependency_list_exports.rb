# frozen_string_literal: true

module API
  class DependencyListExports < ::API::Base
    feature_category :dependency_management
    urgency :low

    before do
      authenticate!
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      desc 'Generate a dependency list export on a project-level'
      post ':id/dependency_list_exports' do
        authorize! :read_dependencies, user_project

        dependency_list_export = ::Dependencies::CreateExportService.new(user_project, current_user).execute

        present dependency_list_export, with: EE::API::Entities::DependencyListExport
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        requires :export_id, types: [Integer, String], desc: 'The ID of the dependency list export'
      end
      desc 'Get a dependency list export'
      get ':id/dependency_list_exports/:export_id' do
        authorize! :read_dependencies, user_project

        dependency_list_export = ::Dependencies::FetchExportService
        .new(params[:export_id].to_i).execute

        if dependency_list_export&.finished?
          present dependency_list_export, with: EE::API::Entities::DependencyListExport
        else
          ::Gitlab::PollingInterval.set_api_header(self, interval: 5_000)
          status :accepted
        end
      end

      desc 'Download a dependency list export'
      get ':id/dependency_list_exports/:export_id/download' do
        authorize! :read_dependencies, user_project

        dependency_list_export = ::Dependencies::FetchExportService
        .new(params[:export_id].to_i).execute

        if dependency_list_export&.finished?
          present_carrierwave_file!(dependency_list_export.file)
        else
          not_found!('DependencyListExport')
        end
      end
    end
  end
end
