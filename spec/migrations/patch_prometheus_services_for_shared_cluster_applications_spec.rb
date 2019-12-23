# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191220102807_patch_prometheus_services_for_shared_cluster_applications.rb')

describe PatchPrometheusServicesForSharedClusterApplications, :migration, :sidekiq do
  include MigrationHelpers::PrometheusServiceHelpers

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }
  let(:clusters) { table(:clusters) }
  let(:cluster_groups) { table(:cluster_groups) }
  let(:clusters_applications_prometheus) { table(:clusters_applications_prometheus) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }

  let(:application_statuses) do
    {
      errored: -1,
      installed: 3,
      updated: 5
    }
  end

  let(:cluster_types) do
    {
      instance_type: 1,
      group_type: 2
    }
  end

  describe '#up' do
    let!(:project_with_missing_service) { projects.create!(name: 'gitlab', path: 'gitlab-ce', namespace_id: namespace.id) }
    let(:project_with_inactive_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
    let(:project_with_active_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
    let(:project_with_manual_active_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
    let(:project_with_manual_inactive_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
    let(:project_with_active_not_prometheus_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
    let(:project_with_inactive_not_prometheus_service) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }

    before do
      services.create(service_params_for(project_with_inactive_service.id, active: false))
      services.create(service_params_for(project_with_active_service.id, active: true))
      services.create(service_params_for(project_with_active_not_prometheus_service.id, active: true, type: 'other'))
      services.create(service_params_for(project_with_inactive_not_prometheus_service.id, active: false, type: 'other'))
      services.create(service_params_for(project_with_manual_inactive_service.id, active: false, properties: { some: 'data' }.to_json))
      services.create(service_params_for(project_with_manual_active_service.id, active: true, properties: { some: 'data' }.to_json))
    end

    shared_examples 'patch prometheus services post migration' do
      context 'prometheus application is installed on the cluster' do
        it 'schedules a background migration' do
          clusters_applications_prometheus.create(cluster_id: cluster.id, status: application_statuses[:installed], version: '123')

          Sidekiq::Testing.fake! do
            Timecop.freeze do
              background_migrations = [["ActivatePrometheusServicesForSharedClusterApplications", project_with_missing_service.id],
                                       ["ActivatePrometheusServicesForSharedClusterApplications", project_with_inactive_service.id],
                                       ["ActivatePrometheusServicesForSharedClusterApplications", project_with_active_not_prometheus_service.id],
                                       ["ActivatePrometheusServicesForSharedClusterApplications", project_with_inactive_not_prometheus_service.id]]

              migrate!

              enqueued_migrations = BackgroundMigrationWorker.jobs.map { |job| job['args'] }
              expect(enqueued_migrations).to match_array(background_migrations)
            end
          end
        end
      end

      context 'prometheus application was recently updated on the cluster' do
        it 'schedules a background migration' do
          clusters_applications_prometheus.create(cluster_id: cluster.id, status: application_statuses[:updated], version: '123')

          Sidekiq::Testing.fake! do
            Timecop.freeze do
              background_migrations = [["ActivatePrometheusServicesForSharedClusterApplications", project_with_missing_service.id],
                                       ["ActivatePrometheusServicesForSharedClusterApplications", project_with_inactive_service.id],
                                       ["ActivatePrometheusServicesForSharedClusterApplications", project_with_active_not_prometheus_service.id],
                                       ["ActivatePrometheusServicesForSharedClusterApplications", project_with_inactive_not_prometheus_service.id]]

              migrate!

              enqueued_migrations = BackgroundMigrationWorker.jobs.map { |job| job['args'] }
              expect(enqueued_migrations).to match_array(background_migrations)
            end
          end
        end
      end

      context 'prometheus application failed to install on the cluster' do
        it 'does not schedule a background migration' do
          clusters_applications_prometheus.create(cluster_id: cluster.id, status: application_statuses[:errored], version: '123')

          Sidekiq::Testing.fake! do
            Timecop.freeze do
              migrate!

              expect(BackgroundMigrationWorker.jobs.size).to eq 0
            end
          end
        end
      end

      context 'prometheus application is NOT installed on the cluster' do
        it 'does not schedule a background migration' do
          Sidekiq::Testing.fake! do
            Timecop.freeze do
              migrate!

              expect(BackgroundMigrationWorker.jobs.size).to eq 0
            end
          end
        end
      end
    end

    context 'Cluster is group_type' do
      let(:cluster) { clusters.create(name: 'cluster', cluster_type: cluster_types[:group_type]) }

      before do
        cluster_groups.create(group_id: namespace.id, cluster_id: cluster.id)
      end

      it_behaves_like 'patch prometheus services post migration'
    end

    context 'Cluster is instance_type' do
      let(:cluster) { clusters.create(name: 'cluster', cluster_type: cluster_types[:instance_type]) }

      it_behaves_like 'patch prometheus services post migration'
    end
  end

  describe '#down' do
    subject(:migration) { described_class.new }

    let(:group) { namespaces.create!(name: 'group', path: 'gitlab-org') }
    let(:project) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: namespace.id) }
    let(:project_with_group_application) { projects.create!(name: 'gitlab', path: 'gitlab-ee', namespace_id: group.id) }
    let!(:active_service_without_application_on_group_cluster) { services.create(service_params_for(project.id, active: true, title: 'to remove')) }
    let!(:duplicated_active_service) { services.create(service_params_for(project_with_group_application.id, active: true)) }
    let!(:inactive_service) { services.create(service_params_for(project_with_group_application.id, active: false)) }
    let!(:manual_inactive_service) { services.create(service_params_for(project.id, active: false, properties: '{\'some\':\'param\'}')) }
    let!(:active_service_group_application) { services.create(service_params_for(project_with_group_application.id, active: true)) }

    before do
      group_cluster = clusters.create(name: 'cluster', cluster_type: cluster_types[:group_type])
      cluster_groups.create(group_id: group.id, cluster_id: group_cluster.id)
      clusters_applications_prometheus.create(cluster_id: group_cluster.id, status: application_statuses[:installed], version: '123')
    end

    context 'application on group cluster' do
      it 'removes only redundant and inconsistent entries' do
        migration.down
        expect(services.all.map(&method(:row_attributes))).to match_array([manual_inactive_service, active_service_group_application].map(&method(:row_attributes)))
      end
    end

    context 'application on instance cluster' do
      it 'removes only redundant and inconsistent entries' do
        instance_cluster = clusters.create(name: 'cluster', cluster_type: cluster_types[:instance_type])
        clusters_applications_prometheus.create(cluster_id: instance_cluster.id, status: application_statuses[:updated], version: '123')

        migration.down

        expected_rows = [active_service_without_application_on_group_cluster, manual_inactive_service, active_service_group_application].map(&method(:row_attributes))
        expect(services.all.map(&method(:row_attributes))).to match_array(expected_rows)
      end
    end
  end
end
