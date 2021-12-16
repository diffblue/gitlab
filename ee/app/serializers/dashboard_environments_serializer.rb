# frozen_string_literal: true

class DashboardEnvironmentsSerializer < BaseSerializer
  include WithPagination

  entity DashboardEnvironmentsProjectEntity

  def represent(resource, opts = {})
    resource = @paginator.paginate(resource) if paginated?

    super(batch_load(resource), opts)
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def batch_load(projects)
    ActiveRecord::Associations::Preloader.new.preload(projects, [
      :route,
      environments_for_dashboard: [
        last_visible_pipeline: [
          :user,
          project: [:route, :group, :project_feature, namespace: :route]
        ],
        last_visible_deployment: [
          deployable: [
            :metadata,
            :pipeline,
            project: [:project_feature, :group, :route, namespace: :route]
          ],
          project: [:route, namespace: :route]
        ],
        project: [:project_feature, :group, namespace: :route]
      ],
      namespace: [:route, :owner]
    ])

    projects
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
