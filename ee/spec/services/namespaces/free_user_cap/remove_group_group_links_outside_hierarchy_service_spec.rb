# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::RemoveGroupGroupLinksOutsideHierarchyService do
  describe '#execute' do
    let_it_be(:namespace, reload: true) { create(:group) }

    let_it_be(:internal_group_link) do
      create(:group_group_link, shared_group: namespace, shared_with_group: create(:group, parent: namespace))
    end

    subject { described_class.new(namespace) }

    context 'when link exists that needs removed' do
      let_it_be(:external_group_link) do
        create(:group_group_link, shared_group: namespace, shared_with_group: create(:group))
      end

      it 'removes the external group' do
        expect { subject.execute }.to change { namespace.shared_with_group_links.count }.by(-1)
        expect(namespace.shared_with_group_links).to match_array([internal_group_link])
      end

      it 'logs an info' do
        expect(Gitlab::AppLogger).to receive(:info)
                                       .with("GroupGroupLinks with ids: [#{external_group_link.id}] have been deleted.")
        expect(Gitlab::AppLogger).to receive(:info).with({
          namespace: namespace.id,
          message: "Removing the GroupGroupLinks outside the hierarchy with ids: [#{external_group_link.id}]"
        })

        subject.execute
      end

      context 'when an error occurs' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:remove_links).and_raise('An exception')
          end
        end

        it 'logs an error' do
          expect(Gitlab::AppLogger).to receive(:error).with({
            namespace: namespace.id,
            message: 'An error has occurred',
            details: 'An exception'
          })

          subject.execute
        end
      end
    end

    context 'when no links exist that need removed' do
      it 'has no change to group links' do
        expect { subject.execute }.not_to change { namespace.shared_with_group_links.count }
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
