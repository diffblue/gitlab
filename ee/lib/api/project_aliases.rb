# frozen_string_literal: true

module API
  class ProjectAliases < ::API::Base
    include PaginationParams

    feature_category :source_code_management

    before { check_feature_availability }
    before { authenticated_as_admin! }

    helpers do
      def project_alias
        ProjectAlias.find_by_name!(params[:name])
      end

      def project
        find_project!(params[:project_id])
      end

      def check_feature_availability
        forbidden! unless ::License.feature_available?(:project_aliases)
      end
    end

    resource :project_aliases do
      desc 'Get a list of all project aliases' do
        success code: 200, model: EE::API::Entities::ProjectAlias
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[project_alias]
      end
      params do
        use :pagination
      end
      get do
        present paginate(ProjectAlias.all), with: EE::API::Entities::ProjectAlias
      end

      desc 'Get info of specific project alias by name' do
        success code: 200, model: EE::API::Entities::ProjectAlias
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[project_alias]
      end
      get ':name' do
        present project_alias, with: EE::API::Entities::ProjectAlias
      end

      desc 'Create a project alias' do
        success code: 201, model: EE::API::Entities::ProjectAlias
        failure [
          { code: 400, message: 'Bad request' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[project_alias]
      end
      params do
        requires :project_id,
          type: String,
          desc: 'The ID or URL-encoded path of the project',
          documentation: { example: 'gitlab-org/gitlab' }
        requires :name,
          type: String,
          desc: 'The alias of the project',
          documentation: { example: 'gitlab' }
      end
      post do
        project_alias = project.project_aliases.create(name: params[:name])

        if project_alias.valid?
          present project_alias, with: EE::API::Entities::ProjectAlias
        else
          render_validation_error!(project_alias)
        end
      end

      desc 'Delete a project alias by name' do
        success code: 204
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[project_alias]
      end
      delete ':name' do
        project_alias.destroy

        no_content!
      end
    end
  end
end
