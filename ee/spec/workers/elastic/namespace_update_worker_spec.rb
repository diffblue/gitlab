# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::NamespaceUpdateWorker, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  subject { described_class.new }

  context 'when elasticsearch indexing is enabled' do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    describe 'for a project' do
      let_it_be(:project_namespace) { create(:project_namespace) }
      let_it_be(:project) { project_namespace.project }

      it 'does not call Elastic::ProcessBookkeepingService.track!' do
        expect(Elastic::ProcessBookkeepingService).not_to receive(:track!)

        subject.perform(project_namespace.id)
      end

      context 'when the project has a member' do
        let_it_be(:project_member) { create(:project_member, project: project, user: user) }

        it 'calls Elastic::ProcessBookkeepingService.track! for the user' do
          expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(*user).once

          subject.perform(project_namespace.id)
        end
      end
    end

    describe 'for a group' do
      let_it_be(:group) { create(:group) }

      it 'does not call Elastic::ProcessBookkeepingService.track!' do
        expect(Elastic::ProcessBookkeepingService).not_to receive(:track!)

        subject.perform(group.id)
      end

      context 'when the group has a member' do
        let_it_be(:group_member) { create(:group_member, group: group, user: user) }

        it 'calls Elastic::ProcessBookkeepingService.track! for the user' do
          expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(*user).once

          subject.perform(group.id)
        end
      end

      context 'when the group has a subgroup with a member' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:subgroup_member) { create(:group_member, group: subgroup, user: user) }

        it 'calls Elastic::ProcessBookkeepingService.track! for the user' do
          expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(*user).once

          subject.perform(group.id)
        end
      end

      context 'when the group has a parent with a member' do
        let_it_be(:parent_group) { create(:group) }
        let_it_be(:parent_group_member) { create(:group_member, group: parent_group, user: user) }

        before do
          group.parent = parent_group
          group.save!
        end

        it 'does not call Elastic::ProcessBookkeepingService.track!' do
          expect(Elastic::ProcessBookkeepingService).not_to receive(:track!)

          subject.perform(group.id)
        end
      end
    end
  end
end
