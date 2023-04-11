# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DestroyService, feature_category: :subgroups do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }

  subject { described_class.new(group, user, {}) }

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { subject.execute }
      let(:fail_condition!) do
        expect_any_instance_of(Group)
          .to receive(:destroy).and_return(group)
      end

      let_it_be(:event_type) { 'group_destroyed' }

      let(:attributes) do
        {
           author_id: user.id,
           entity_id: group.id,
           entity_type: 'Group',
           details: {
             remove: 'group',
             author_name: user.name,
             author_class: user.class.name,
             target_id: group.id,
             target_type: 'Group',
             target_details: group.full_path,
             custom_message: 'Group destroyed'
           }
         }
      end
    end
  end

  context 'streaming audit event for sub group' do
    let(:parent_group) { create :group }
    let(:group) { create :group, parent: parent_group }

    subject { described_class.new(group, user, {}).execute }

    before do
      parent_group.add_owner(user)
      stub_licensed_features(external_audit_events: true)
      parent_group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    it 'sends the audit streaming event with json format' do
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
        'group_destroyed',
        nil,
        a_string_including("group_entity_id\":#{parent_group.id}"))

      subject
    end
  end

  context 'dependency_proxy_blobs' do
    let_it_be(:blob) { create(:dependency_proxy_blob) }
    let_it_be(:group) { blob.group }

    before do
      group.add_maintainer(user)
    end

    it 'destroys the dependency proxy blobs' do
      expect { subject.execute }.to change { DependencyProxy::Blob.count }.by(-1)
    end
  end

  context 'when on a Geo primary node' do
    before do
      allow(Gitlab::Geo).to receive(:primary?) { true }
    end

    context 'when group_wiki_repository does not exist' do
      it 'does not call replicator to update Geo' do
        expect_next_instance_of(Geo::GroupWikiRepositoryReplicator).never

        subject.execute
      end
    end

    it 'calls replicator to update Geo' do
      group.wiki.create_wiki_repository

      expect(group.group_wiki_repository.replicator).to receive(:handle_after_destroy)

      subject.execute
    end
  end

  context 'when not on a Geo primary node' do
    it 'does not call replicator to update Geo' do
      group.wiki.create_wiki_repository

      expect(group.group_wiki_repository.replicator).not_to receive(:handle_after_destroy)

      subject.execute
    end
  end

  context 'when group epics have parent epic outside of group' do
    let!(:parent_group) { create(:group) }
    let!(:group) { create(:group, parent: parent_group) }
    let!(:parent_epic1) { create(:epic, group: parent_group) }
    let!(:parent_epic2) { create(:epic, group: parent_group) }
    let!(:parent_epic3) { create(:epic, group: parent_group) }
    let!(:epic1) { create(:epic, group: group, parent: parent_epic1) }
    let!(:epic2) { create(:epic, group: group, parent: parent_epic2) }
    let!(:epic3) { create(:epic, group: group, parent: parent_epic3) }
    # update should not be called for this as parent is in the same group:
    let!(:epic4) { create(:epic, group: group, parent: epic2) }

    before do
      group.add_maintainer(user)
    end

    it 'schedules cache update for associated epics in batches' do
      stub_const('::Epics::UpdateCachedMetadataWorker::BATCH_SIZE', 2)

      expect(::Epics::UpdateCachedMetadataWorker).to receive(:bulk_perform_in) do |delay, ids|
        expect(delay).to eq(1.minute)
        expect(ids.map(&:first).map(&:length)).to eq([2, 1])
        expect(ids.flatten).to match_array([parent_epic1.id, parent_epic2.id, parent_epic3.id])
      end.once

      subject.execute
    end
  end
end
