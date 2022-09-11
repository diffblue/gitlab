# frozen_string_literal: true

namespace :gitlab do
  namespace :seed do
    desc "GitLab | Metrics | Setup development metrics"
    task :development_metrics, [:project_id] => :gitlab_environment do |_, args|
      shared_multi_metrics_attributes = {
        title: 'Memory multi metric',
        y_label: 'Memory (GiB)',
        project_id: args.project_id,
        unit: 'GiB',
        group: 'system'
      }
      PrometheusMetric.find_or_create_by(
        **shared_multi_metrics_attributes,
        identifier: "#{args.project_id}-additional_system_metrics_container_memory_usage",
        legend: 'Usage (GiB)',
        query: 'avg(sum(container_memory_usage_bytes{id="/"}) by (job)) without (job) / 2^30'
      )
      PrometheusMetric.find_or_create_by(
        **shared_multi_metrics_attributes,
        identifier: "#{args.project_id}-additional_system_metrics_kube_node_status_capacity_memory_bytes",
        query: 'sum(kube_node_status_capacity_memory_bytes{kubernetes_namespace="gitlab-managed-apps"})/2^30',
        legend: 'Capacity (GiB)'
      )
      PrometheusMetric.find_or_create_by(
        **shared_multi_metrics_attributes,
        identifier: "#{args.project_id} additional_system_metrics_kube_pod_container_resource_requests_memory_bytes",
        query: 'sum(kube_pod_container_resource_requests_memory_bytes{kubernetes_namespace="gitlab-managed-apps"})/2^30',
        legend: 'Requested (GiB)'
      )

      project = Project.find(args.project_id)
      content = File.read(Rails.root.join('spec', 'fixtures', 'lib', 'gitlab', 'metrics', 'dashboard', 'development_metrics.yml'))
      file_attributes = [
        project.creator,
        '.gitlab/dashboards/development_metrics.yml',
        content,
        {
          message: 'Seeded development metrics',
          branch_name: 'master'
        }
      ]

      begin
        project.repository.create_file(*file_attributes)
      rescue Gitlab::Git::Index::IndexError => error
        raise error unless error.message == 'A file with this name already exists'

        project.repository.update_file(*file_attributes)
      end
    end
  end
end
