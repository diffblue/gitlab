# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::TransferService, '#execute', feature_category: :subgroups do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:new_group) { create(:group, :public) }
  let(:transfer_service) { described_class.new(group, user) }

  before do
    group.add_owner(user)
    new_group&.add_owner(user)
  end

  describe '#execute' do
    it 'transfers a group successfully' do
      transfer_service.execute(new_group)

      expect(group.parent).to eq(new_group)
    end

    context 'when SAML provider or SCIM token is configured for the group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:parent_group) { create(:group, :private) }

      before do
        group.add_owner(user)
        parent_group.add_owner(user)
      end

      shared_examples_for 'raises error for paid group' do
        before do
          allow(group).to receive(:paid?).and_return true
        end

        it 'returns false' do
          expect(transfer_service.execute(parent_group)).to be_falsy
        end

        it 'does not add saml provider error' do
          transfer_service.execute(parent_group)

          expect(transfer_service.error).not_to eq('Transfer failed: SAML Provider or SCIM Token is configured for this group.')
        end
      end

      context 'when the group has a scim token' do
        before do
          create(:scim_oauth_access_token, group: group)
        end

        it_behaves_like 'raises error for paid group'

        it 'adds an error on group' do
          transfer_service.execute(parent_group)

          expect(transfer_service.error).to eq('Transfer failed: SAML Provider or SCIM Token is configured for this group.')
        end
      end

      context 'when the group has a saml provider' do
        before do
          create(:saml_provider, group: group)
        end

        it_behaves_like 'raises error for paid group'

        it 'adds an error on group' do
          transfer_service.execute(parent_group)

          expect(transfer_service.error).to eq('Transfer failed: SAML Provider or SCIM Token is configured for this group.')
        end
      end
    end
  end

  describe 'elasticsearch indexing', :aggregate_failures do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    context 'when elasticsearch_limit_indexing is on' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      context 'when moving from a non-indexed namespace to an indexed namespace' do
        before do
          create(:elasticsearch_indexed_namespace, namespace: new_group)
        end

        it 'invalidates the namespace and project cache and indexes the project and all associated data' do
          expect(project).not_to receive(:maintain_elasticsearch_update)
          expect(project).not_to receive(:maintain_elasticsearch_destroy)
          expect(::Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
          expect(::Gitlab::CurrentSettings).to receive(:invalidate_elasticsearch_indexes_cache_for_project!).with(project.id).and_call_original
          expect(::Gitlab::CurrentSettings).to receive(:invalidate_elasticsearch_indexes_cache_for_namespace!).with(group.id).and_call_original

          transfer_service.execute(new_group)
        end
      end

      context 'when both namespaces are indexed' do
        before do
          create(:elasticsearch_indexed_namespace, namespace: group)
          create(:elasticsearch_indexed_namespace, namespace: new_group)
        end

        it 'invalidates the namespace and project cache and indexes the project and all associated data' do
          expect(project).not_to receive(:maintain_elasticsearch_update)
          expect(project).not_to receive(:maintain_elasticsearch_destroy)
          expect(::Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project)
          expect(::Gitlab::CurrentSettings).to receive(:invalidate_elasticsearch_indexes_cache_for_project!).with(project.id).and_call_original
          expect(::Gitlab::CurrentSettings).to receive(:invalidate_elasticsearch_indexes_cache_for_namespace!).with(group.id).and_call_original

          transfer_service.execute(new_group)
        end
      end
    end

    context 'when elasticsearch_limit_indexing is off' do
      let(:new_group) { create(:group, :private) }

      it 'does not invalidate the namespace or project cache and reindexes projects and associated data' do
        project1 = create(:project, :repository, :public, namespace: group)
        project2 = create(:project, :repository, :public, namespace: group)
        project3 = create(:project, :repository, :private, namespace: group)

        expect(::Gitlab::CurrentSettings).not_to receive(:invalidate_elasticsearch_indexes_cache_for_namespace!)
        expect(::Gitlab::CurrentSettings).not_to receive(:invalidate_elasticsearch_indexes_cache_for_project!)
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project1)
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project2)
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project3)

        transfer_service.execute(new_group)

        expect(transfer_service.error).not_to be
        expect(group.parent).to eq(new_group)
      end
    end
  end

  context 'with epics' do
    context 'when epics feature is disabled' do
      it 'transfers a group successfully' do
        transfer_service.execute(new_group)

        expect(group.parent).to eq(new_group)
      end
    end

    context 'when epics feature is enabled' do
      let(:root_group) { create(:group) }
      let(:subgroup_group_level_1) { create(:group, parent: root_group) }
      let(:subgroup_group_level_2) { create(:group, parent: subgroup_group_level_1) }
      let(:subgroup_group_level_3) { create(:group, parent: subgroup_group_level_2) }

      let!(:root_epic) { create(:epic, group: root_group) }
      let!(:level_1_epic_1) { create(:epic, group: subgroup_group_level_1, parent: root_epic) }
      let!(:level_1_epic_2) { create(:epic, group: subgroup_group_level_1, parent: level_1_epic_1) }
      let!(:level_2_epic_1) { create(:epic, group: subgroup_group_level_2, parent: root_epic) }
      let!(:level_2_epic_2) { create(:epic, group: subgroup_group_level_2, parent: level_1_epic_1) }
      let!(:level_2_subepic) { create(:epic, group: subgroup_group_level_2, parent: level_2_epic_2) }
      let!(:level_3_epic) { create(:epic, group: subgroup_group_level_3, parent: level_2_epic_2) }

      before do
        root_group.add_owner(user)

        stub_licensed_features(epics: true)
      end

      context 'when group is moved completely out of the main group' do
        it 'keeps relations between all epics' do
          described_class.new(subgroup_group_level_1, user).execute(new_group)

          expect(level_1_epic_2.reload.parent).to eq(level_1_epic_1)
          expect(level_2_epic_2.reload.parent).to eq(level_1_epic_1)
          expect(level_2_subepic.reload.parent).to eq(level_2_epic_2)
          expect(level_3_epic.reload.parent).to eq(level_2_epic_2)
          expect(level_1_epic_1.reload.parent).to eq(root_epic)
          expect(level_2_epic_1.reload.parent).to eq(root_epic)
        end
      end

      context 'when group is moved some levels up' do
        it 'keeps relations between all epics' do
          described_class.new(subgroup_group_level_2, user).execute(root_group)

          expect(level_1_epic_1.reload.parent).to eq(root_epic)
          expect(level_1_epic_2.reload.parent).to eq(level_1_epic_1)
          expect(level_2_epic_1.reload.parent).to eq(root_epic)
          expect(level_2_subepic.reload.parent).to eq(level_2_epic_2)
          expect(level_3_epic.reload.parent).to eq(level_2_epic_2)
          expect(level_2_epic_2.reload.parent).to eq(level_1_epic_1)
        end
      end

      describe 'update cached metadata' do
        subject { described_class.new(subgroup_group_level_1, user).execute(new_group) }

        it 'does not schedule update of issue counts' do
          expect(::Epics::UpdateCachedMetadataWorker).not_to receive(:bulk_perform_in)

          subject
        end
      end
    end
  end

  describe '.update_project_settings' do
    let(:project_settings) { create_list(:project_setting, 2, legacy_open_source_license_available: true) }

    it 'sets `legacy_open_source_license_available` to false' do
      transfer_service.send(:update_project_settings, project_settings.pluck(:project_id))

      project_settings.each(&:reload)
      expect(project_settings.pluck(:legacy_open_source_license_available)).to match_array([false, false])
    end
  end
end
