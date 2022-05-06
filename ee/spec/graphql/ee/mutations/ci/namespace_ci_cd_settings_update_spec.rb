# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::NamespaceCiCdSettingsUpdate do
  include GraphqlHelpers

  let_it_be(:namespace) do
    create(:group, :public, allow_stale_runner_pruning: true).tap(&:save!)
  end

  let(:mutation_params) do
    {
      full_path: namespace.full_path,
      allow_stale_runner_pruning: false
    }
  end

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  subject(:request) { mutation.resolve(full_path: namespace.full_path, **mutation_params) }

  context 'when unauthorized' do
    let(:user) { create(:user) }

    shared_examples 'unauthorized' do
      it 'returns an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when not a namespace member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-admin namespace member' do
      before do
        namespace.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    let_it_be(:user) { create(:user) }

    before do
      namespace.add_owner(user)
    end

    it 'updates allow_stale_runner_pruning?' do
      request

      expect(namespace.reload.allow_stale_runner_pruning?).to eq(false)
    end

    it 'does not update allow_stale_runner_pruning? if not specified' do
      mutation_params.except!(:allow_stale_runner_pruning)

      request

      expect(namespace.reload.allow_stale_runner_pruning?).to eq(true)
    end
  end
end
