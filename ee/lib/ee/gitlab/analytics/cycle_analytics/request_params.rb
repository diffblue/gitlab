# frozen_string_literal: true

module EE
  module Gitlab
    module Analytics
      module CycleAnalytics
        module RequestParams
          include ::Gitlab::Utils::StrongMemoize
          extend ::Gitlab::Utils::Override

          override :to_data_attributes
          def to_data_attributes
            super.tap do |attrs|
              attrs[:aggregation] = aggregation_attributes if use_aggregated_backend?
              attrs[:group] = group_data_attributes if group.present?
              attrs[:projects] = group_projects(project_ids) if group.present? && project_ids.present?
              attrs[:enable_tasks_by_type_chart] = 'true' if group.present?
              attrs[:enable_customizable_stages] = 'true' if licensed?
              attrs[:enable_projects_filter] = 'true' if group.present?
            end
          end

          private

          override :namespace_attributes
          def namespace_attributes
            return super if project
            return {} if group.nil?

            {
              name: group.name,
              full_path: "groups/#{group.full_path}",
              type: namespace.type
            }
          end

          override :resource_paths
          def resource_paths
            paths = super
            return paths unless group.present?

            paths.merge({
              milestones_path: url_helpers.group_milestones_path(group, format: :json),
              labels_path: url_helpers.group_labels_path(group, format: :json)
            })
          end

          override :use_aggregated_backend?
          def use_aggregated_backend?
            super || licensed?
          end

          def aggregation_attributes
            {
              enabled: aggregation.enabled.to_s,
              last_run_at: aggregation.last_incremental_run_at&.iso8601,
              next_run_at: aggregation.estimated_next_run_at&.iso8601
            }
          end

          def aggregation
            @aggregation ||= ::Analytics::CycleAnalytics::Aggregation.safe_create_for_namespace(namespace)
          end

          def group_projects(project_ids)
            ::GroupProjectsFinder.new(
              group: namespace,
              current_user: current_user,
              options: { include_subgroups: true },
              project_ids_relation: project_ids
            )
              .execute
              .with_route
              .map { |project| project_data_attributes(project) }
              .to_json
          end

          def project_data_attributes(project)
            {
              id: project.to_gid.to_s,
              name: project.name,
              path_with_namespace: project.path_with_namespace,
              avatar_url: project.avatar_url
            }
          end

          def group_data_attributes
            return unless group

            {
              id: namespace.id,
              namespace_id: namespace.id,
              name: namespace.name,
              full_path: namespace.full_path,
              avatar_url: namespace.avatar_url
            }
          end

          def group
            namespace if namespace.is_a?(Group) && licensed?
          end
          strong_memoize_attr :group

          def licensed?
            ::Gitlab::Analytics::CycleAnalytics.licensed?(namespace)
          end
        end
      end
    end
  end
end
