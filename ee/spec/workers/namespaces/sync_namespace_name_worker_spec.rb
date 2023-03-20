# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::SyncNamespaceNameWorker, type: :worker, feature_category: :saas_provisioning do
  let_it_be(:namespace) { create(:group) }

  describe '#perform' do
    let(:namespace_id) { namespace.id }

    subject(:sync) do
      described_class.new.perform(namespace_id)
    end

    context 'when the namespace is not found' do
      let(:namespace_id) { 'ABC' }

      it 'does not trigger a sync for the namespace name to CustomersDot' do
        expect(Gitlab::SubscriptionPortal::Client).not_to receive(:update_namespace_name)

        sync
      end

      it 'does not raise an error' do
        expect { sync }.not_to raise_error
      end
    end

    context 'when the sync fails' do
      it 'raises a RequestError' do
        expect(Gitlab::SubscriptionPortal::Client).to receive(:update_namespace_name)
          .and_return({ success: false, errors: 'foo' })

        expect { sync }.to raise_error(
          described_class::RequestError,
          %(Namespace name sync failed! Namespace id: #{namespace_id}, {:success=>false, :errors=>"foo"})
        )
      end
    end

    it 'triggers a sync for the namespace name to CustomersDot' do
      expect(Gitlab::SubscriptionPortal::Client).to receive(:update_namespace_name)
        .with(namespace.id, namespace.name)
        .and_return({ success: true })

      sync
    end
  end
end
