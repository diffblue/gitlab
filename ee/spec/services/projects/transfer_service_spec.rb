# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TransferService do
  include EE::GeoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }

  let(:project) { create(:project, :repository, :public, :legacy_storage, namespace: user.namespace) }

  subject { described_class.new(project, user) }

  before do
    group.add_owner(user)
  end

  context 'when running on a primary node' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    it 'logs an event to the Geo event log' do
      stub_current_geo_node(primary)

      expect { subject.execute(group) }.to change(Geo::RepositoryRenamedEvent, :count).by(1)
    end
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { subject.execute(group) }
      let(:fail_condition!) do
        expect_next_instance_of(Project) do |instance|
          expect(instance).to receive(:has_container_registry_tags?).and_return(true)
        end
      end

      let(:attributes) do
        {
           author_id: user.id,
           entity_id: project.id,
           entity_type: 'Project',
           details: {
             change: 'namespace',
             from: project.old_path_with_namespace,
             to: project.full_path,
             author_name: user.name,
             target_id: project.id,
             target_type: 'Project',
             target_details: project.full_path
           }
         }
      end
    end
  end

  context 'missing epics applied to issues' do
    it 'delegates transfer to Epics::TransferService' do
      expect_next_instance_of(Epics::TransferService, user, project.group, project) do |epics_transfer_service|
        expect(epics_transfer_service).to receive(:execute).once.and_call_original
      end

      subject.execute(group)
    end
  end

  describe 'elasticsearch indexing', :elastic, :clean_gitlab_redis_shared_state, :aggregate_failures do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    context 'when visibility level changes' do
      let_it_be(:group) { create(:group, :private) }

      it 'reindexes the project and associated issues and notes' do
        expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(project)
        expect(ElasticAssociationIndexerWorker).to receive(:perform_async).with('Project', project.id, %w[issues merge_requests notes])

        subject.execute(group)
      end
    end

    context 'when elasticsearch_limit_indexing is on' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      context 'when transferring between a non-indexed namespace and an indexed namespace' do
        before do
          create(:elasticsearch_indexed_namespace, namespace: group)
        end

        it 'invalidates the cache and indexes the project and all associated data' do
          expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
          expect(project).not_to receive(:maintain_elasticsearch_destroy)
          expect(::Gitlab::CurrentSettings).to receive(:invalidate_elasticsearch_indexes_cache_for_project!).with(project.id).and_call_original

          subject.execute(group)
        end
      end

      context 'when both namespaces are indexed' do
        before do
          create(:elasticsearch_indexed_namespace, namespace: group)
          create(:elasticsearch_indexed_namespace, namespace: project.namespace)
        end

        it 'does not invalidate the cache does not index or delete anything' do
          expect(Elastic::ProcessInitialBookkeepingService).not_to receive(:backfill_projects!).with(project)
          expect(project).not_to receive(:maintain_elasticsearch_destroy)
          expect(::Gitlab::CurrentSettings).not_to receive(:invalidate_elasticsearch_indexes_cache_for_project!)

          subject.execute(group)
        end
      end
    end

    context 'when elasticsearch_limit_indexing is off' do
      it 'does not invalidate the cache and reindexes the project only' do
        expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(project)
        expect(ElasticAssociationIndexerWorker).not_to receive(:perform_async)
        expect(::Gitlab::CurrentSettings).not_to receive(:invalidate_elasticsearch_indexes_cache_for_project!).with(project.id).and_call_original

        subject.execute(group)
      end
    end
  end

  describe 'project access tokens' do
    let_it_be(:premium_group) { create(:group_with_plan, plan: :premium_plan) }
    let_it_be(:free_group) { create(:group) }

    before do
      premium_group.add_owner(user)
      free_group.add_owner(user)

      ResourceAccessTokens::CreateService.new(user, project).execute
    end

    def revoked_tokens
      PersonalAccessToken.without_impersonation.for_users(project.bots).revoked
    end

    context 'with a self managed instance' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: false)
      end

      it 'does not revoke PATs' do
        subject.execute(group)

        expect { subject.execute(group) }.not_to change { revoked_tokens.count }
      end
    end

    context 'with GL.com' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when target namespace has a premium plan' do
        it 'does not revoke PATs' do
          subject.execute(premium_group)

          expect { subject.execute(group) }.not_to change { revoked_tokens.count }
        end
      end

      context 'when target namespace has a free plan' do
        it 'revoke PATs' do
          expect { subject.execute(free_group) }.to change { revoked_tokens.count }.from(0).to(1)
        end
      end
    end
  end
end
