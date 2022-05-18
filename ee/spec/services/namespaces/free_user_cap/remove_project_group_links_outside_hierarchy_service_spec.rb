# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::RemoveProjectGroupLinksOutsideHierarchyService do
  describe '#execute', :aggregate_failures do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project) { create(:project, group: namespace) }

    let_it_be(:internal_group_link) do
      create(:project_group_link, project: project, group: create(:group, parent: namespace))
    end

    subject { described_class.new(namespace) }

    before_all do
      create(:project_group_link)
    end

    context 'when link exists that needs to be removed' do
      let_it_be(:external_group_link) { create(:project_group_link, project: project) }

      it 'removes the external group' do
        expect { subject.execute }.to change { ProjectGroupLink.in_project(namespace.all_projects).count }.by(-1)
        expect(ProjectGroupLink.in_project(namespace.all_projects)).to match_array([internal_group_link])
      end

      it 'logs an info' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          {
            namespace: namespace.id,
            message: "Removing the ProjectGroupLinks outside the hierarchy with ids: [#{external_group_link.id}]"
          }
        )

        subject.execute
      end

      context 'when multiple projects exist in the namespace' do
        let_it_be(:project_2) { create(:project, group: namespace) }
        let_it_be(:external_group_link_2) { create(:project_group_link, project: project_2) }
        let_it_be(:internal_group_link_2) do
          create(:project_group_link, project: project_2, group: create(:group, parent: namespace))
        end

        it 'removes the external groups' do
          expect { subject.execute }.to change { ProjectGroupLink.in_project(namespace.all_projects).count }.by(-2)
          expect(ProjectGroupLink.in_project(namespace.all_projects))
            .to match_array([internal_group_link, internal_group_link_2])
        end

        it 'logs an info' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            {
              namespace: namespace.id,
              message: /Removing the ProjectGroupLinks outside the hierarchy with ids: /
            }
          )

          subject.execute
        end
      end

      context 'when an error occurs' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:remove_links).and_raise('An exception')
          end
        end

        it 'logs an error' do
          expect(Gitlab::AppLogger).to receive(:error).with(
            {
              namespace: namespace.id,
              message: 'An error has occurred',
              details: 'An exception'
            }
          )

          subject.execute
        end
      end
    end

    context 'when no links exist that need to be removed' do
      it 'has no change to group links' do
        expect { subject.execute }.not_to change { project.project_group_links.count }
      end

      it 'does not log' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        subject.execute
      end
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it 'does not log' do
        expect(Gitlab::AppLogger).not_to receive(:info)
        expect(Gitlab::AppLogger).not_to receive(:error)

        subject.execute
      end
    end
  end
end
