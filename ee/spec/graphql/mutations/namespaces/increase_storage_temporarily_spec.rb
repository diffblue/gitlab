# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Namespaces::IncreaseStorageTemporarily, :saas do
  include NamespaceStorageHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { user.namespace }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    subject { mutation.resolve(id: namespace.to_global_id) }

    before do
      enforce_namespace_storage_limit(namespace)

      allow_next_instance_of(Namespaces::Storage::RootSize, namespace) do |root_storage|
        allow(root_storage).to receive(:usage_ratio).and_return(0.5)
      end
    end

    context 'when user is not the admin of the namespace' do
      let(:user) { create(:user) }

      it 'raises a not accessible error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user can admin the namespace' do
      it 'sets temporary_storage_increase_ends_on' do
        expect(namespace.temporary_storage_increase_ends_on).to be_nil

        subject

        expect(subject[:namespace]).to be_present
        expect(subject[:errors]).to be_empty
        expect(namespace.reload.temporary_storage_increase_ends_on).to be_present
      end
    end
  end
end
