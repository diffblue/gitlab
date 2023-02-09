# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PostReceiveService, :geo do
  include EE::GeoHelpers

  let_it_be(:primary_url) { 'http://primary.example.com' }
  let_it_be(:secondary_url) { 'http://secondary.example.com' }
  let_it_be(:primary_node, reload: true) { create(:geo_node, :primary, url: primary_url) }
  let_it_be(:secondary_node, reload: true) { create(:geo_node, url: secondary_url) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:gl_repository) { "project-#{project.id}" }
  let(:repository) { project.repository }
  let(:identifier) { 'key-123' }
  let(:git_push_http) { double('GitPushHttp') }

  let(:params) do
    {
      gl_repository: gl_repository,
      identifier: identifier,
      changes: []
    }
  end

  subject do
    service = described_class.new(user, repository, project, params)
    service.execute.messages.as_json
  end

  describe 'Geo' do
    before do
      stub_current_geo_node(primary_node)

      allow(Gitlab::Geo::GitPushHttp).to receive(:new).with(identifier, gl_repository).and_return(git_push_http)
      allow(git_push_http).to receive(:fetch_referrer_node).and_return(node)
    end

    context 'when the push was redirected from a Geo secondary to the primary' do
      let(:node) { secondary_node }

      context 'when the secondary has a GeoNodeStatus' do
        let!(:status) { create(:geo_node_status, geo_node: secondary_node, db_replication_lag_seconds: db_replication_lag_seconds) }

        context 'when the GeoNodeStatus db_replication_lag_seconds is greater than 0' do
          let(:db_replication_lag_seconds) { 17 }

          it 'includes current Geo secondary lag in the output' do
            expect(subject).to include({
              'type' => 'basic',
              'message' => "Current replication lag: 17 seconds"
            })
          end
        end

        context 'when the GeoNodeStatus db_replication_lag_seconds is 0' do
          let(:db_replication_lag_seconds) { 0 }

          it 'does not include current Geo secondary lag in the output' do
            expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
          end
        end

        context 'when the GeoNodeStatus db_replication_lag_seconds is nil' do
          let(:db_replication_lag_seconds) { nil }

          it 'does not include current Geo secondary lag in the output' do
            expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
          end
        end
      end

      context 'when the secondary does not have a GeoNodeStatus' do
        it 'does not include current Geo secondary lag in the output' do
          expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
        end
      end

      it 'includes a message advising a redirection occurred' do
        redirect_message = <<~STR
        This request to a Geo secondary node will be forwarded to the
        Geo primary node:

          http://primary.example.com/#{project.full_path}.git
        STR

        expect(subject).to include({
          'type' => 'basic',
          'message' => redirect_message
        })
      end
    end

    context 'when the push was not redirected from a Geo secondary to the primary' do
      let(:node) { nil }

      it 'does not include current Geo secondary lag in the output' do
        expect(subject).not_to include({ 'message' => a_string_matching('replication lag'), 'type' => anything })
      end
    end
  end

  describe 'storage size limit alerts', feature_category: :subscription_cost_management do
    context 'when there is no alert' do
      before do
        allow_next_instance_of(Namespaces::Storage::CliNotification, project.namespace, user) do |notification|
          allow(notification).to receive(:show?).and_return(false)
        end
      end

      it 'returns no messages' do
        expect(subject).to be_empty
      end
    end

    context 'when there is an alert' do
      before do
        stub_ee_application_setting(automatic_purchased_storage_allocation: true)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when repository size limit enforcement' do
        let(:user) { project.namespace.owner }
        let(:contains_locked_projects) { true }

        include RepositoryStorageHelpers

        it 'returns error message' do
          stub_over_repository_limit(project.namespace, contains_locked_projects)

          expect(subject).to match_array([{ "message" => "##### ERROR #####\nYou have reached the free storage limit of 10 Bytes " \
                                                         "on one or more projects.\nPlease purchase additional storage to unlock " \
                                                         "your projects over the free 10 Bytes project limit. " \
                                                         "You can't push to your repository, create pipelines, " \
                                                         "create issues or add comments. To reduce storage capacity, " \
                                                         "delete unused repositories, artifacts, wikis, issues, and pipelines.", "type" => "alert" }])
        end
      end

      context 'when namespace size limit enforcement' do
        before do
          stub_ee_application_setting(automatic_purchased_storage_allocation: true)
          stub_ee_application_setting(should_check_namespace_plan: true)
          stub_ee_application_setting(enforce_namespace_storage_limit: true)
          allow_next_instance_of(Namespaces::Storage::RootSize) do |root_storage_size|
            allow(root_storage_size).to receive(:current_size).and_return(11.5)
            allow(root_storage_size).to receive(:limit).and_return(12)
          end
        end

        context 'with a personal namespace' do
          let_it_be(:project) { create(:project, namespace: user.namespace) }

          it 'returns warning message' do
            expect(subject).to match_array([{ "message" => "##### WARNING #####\nYou have used 96% of the storage quota for #{project.namespace.name} " \
                                                           "(11 Bytes of 12 Bytes).\nIf #{project.namespace.name} exceeds the storage quota, " \
                                                           "all projects in the namespace will be locked and actions will be restricted. " \
                                                           "To manage storage, or purchase additional storage, " \
                                                           "see http://localhost/help/user/usage_quotas#manage-your-storage-usage. " \
                                                           "To learn more about restricted actions, see http://localhost/help/user/read_only_namespaces#restricted-actions", "type" => "alert" }])
          end
        end

        context 'with a group namespace' do
          let_it_be(:group) { create(:group) }
          let_it_be(:project) { create(:project, namespace: group) }

          before do
            group.add_owner(user)
          end

          it 'returns warning message' do
            expect(subject).to match_array([{ "message" => "##### WARNING #####\nYou have used 96% of the storage quota for #{group.name} " \
                                                           "(11 Bytes of 12 Bytes).\nIf #{group.name} exceeds the storage quota, " \
                                                           "all projects in the namespace will be locked and actions will be restricted. " \
                                                           "To manage storage, or purchase additional storage, " \
                                                           "see http://localhost/help/user/usage_quotas#manage-your-storage-usage. " \
                                                           "To learn more about restricted actions, see http://localhost/help/user/read_only_namespaces#restricted-actions", "type" => "alert" }])
          end
        end
      end
    end
  end
end
