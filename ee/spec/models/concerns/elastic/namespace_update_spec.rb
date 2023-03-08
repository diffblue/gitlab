# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::NamespaceUpdate, feature_category: :global_search do
  describe 'when changing parent_id' do
    let_it_be_with_reload(:namespace) { create(:group) }
    let_it_be(:parent_namespace) { create(:group) }

    it 'does not enqueue Elastic::NamespaceUpdateWorker' do
      expect(::Elastic::NamespaceUpdateWorker).not_to receive(:perform_async)

      namespace.update!(parent_id: parent_namespace.id)
    end

    context 'when elastic indexing is enabled' do
      before do
        allow(Gitlab::CurrentSettings).to(receive(:elasticsearch_indexing?)).and_return(true)
      end

      it 'enqueues Elastic::NamespaceUpdateWorker' do
        expect(::Elastic::NamespaceUpdateWorker).to receive(:perform_async).once

        namespace.update!(parent_id: parent_namespace.id)
      end

      describe 'when transfering a group' do
        let_it_be_with_reload(:group) { create(:group) }
        let_it_be(:parent) { create(:group) }
        let_it_be(:user) { create(:user) }
        let_it_be(:member) { create(:group_member, :owner, group: group, user: user) }
        let_it_be(:parent_member) { create(:group_member, :owner, group: parent, user: user) }

        it 'enqueues Elastic::NamespaceUpdateWorker when changing parent from nil' do
          expect(::Elastic::NamespaceUpdateWorker).to receive(:perform_async).once

          Groups::TransferService.new(group, user).execute(parent)
        end

        it 'enqueues Elastic::NamespaceUpdateWorker when changing parent to nil' do
          group.update!(parent_id: parent.id)

          expect(Elastic::NamespaceUpdateWorker).to receive(:perform_async).once

          Groups::TransferService.new(group, user).execute(nil)
        end
      end

      describe 'when transfering a project' do
        let_it_be_with_reload(:project) { create(:project) }
        let_it_be(:group) { create(:group) }
        let_it_be(:user) { create(:user) }
        let_it_be(:member) { create(:project_member, :owner, project: project, user: user) }
        let_it_be(:group_member) { create(:group_member, :owner, group: group, user: user) }

        it 'enqueues Elastic::NamespaceUpdateWorker when changing parent' do
          expect(Elastic::NamespaceUpdateWorker).to receive(:perform_async).once

          Projects::TransferService.new(project, user).execute(group)
        end
      end
    end
  end
end
