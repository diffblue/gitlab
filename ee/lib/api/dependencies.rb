# frozen_string_literal: true

module API
  class Dependencies < ::API::Base
    include PaginationParams

    feature_category :dependency_management
    urgency :low

    helpers do
      def dependencies_by(params)
        pipeline = ::Security::ReportFetchService.new(user_project, ::Ci::JobArtifact.of_report_type(:dependency_list)).pipeline

        return [] unless pipeline

        ::Security::DependencyListService.new(pipeline: pipeline, params: params).execute
      end
    end

    before { authenticate! }

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project dependencies' do
        success code: 200, model: ::EE::API::Entities::Dependency
        failure [{ code: 401, message: 'Unauthorized' }, { code: 404, message: 'Not found' }]
      end

      params do
        optional :package_manager,
          type: Array[String],
          coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
          desc: "Returns dependencies belonging to specified package managers: #{::Security::DependencyListService::FILTER_PACKAGE_MANAGERS_VALUES.join(', ')}.",
          values: ::Security::DependencyListService::FILTER_PACKAGE_MANAGERS_VALUES,
          documentation: { example: 'maven,yarn' }
        use :pagination
      end

      get ':id/dependencies' do
        authorize! :read_dependencies, user_project

        ::Gitlab::Tracking.event(self.options[:for].name, 'view_dependencies', project: user_project, user: current_user, namespace: user_project.namespace)

        dependency_params = declared_params(include_missing: false).merge(project: user_project)
        dependencies = paginate(::Gitlab::ItemsCollection.new(dependencies_by(dependency_params)))

        present dependencies, with: ::EE::API::Entities::Dependency, user: current_user, project: user_project
      end
    end
  end
end
