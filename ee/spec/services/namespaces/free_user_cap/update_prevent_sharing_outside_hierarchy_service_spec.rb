# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::UpdatePreventSharingOutsideHierarchyService do
  describe '#execute' do
    let_it_be(:namespace, reload: true) { create(:namespace, :with_namespace_settings) }

    subject { described_class.new(namespace) }

    it 'sets setting to true' do
      expect { subject.execute }
        .to change { namespace.prevent_sharing_groups_outside_hierarchy }.from(false).to(true)
    end

    it 'logs an info' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        {
          namespace: namespace.id,
          message: "Setting the namespace setting for prevent_sharing_groups_outside_hierarchy to true"
        }
      )

      subject.execute
    end

    context 'when already set to true' do
      before do
        namespace.update_attribute(:prevent_sharing_groups_outside_hierarchy, true)
      end

      it 'makes no setting change' do
        expect { subject.execute }
          .not_to change { namespace.prevent_sharing_groups_outside_hierarchy }
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

    context 'when an error occurs' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:update_setting).and_raise('An exception')
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
end
