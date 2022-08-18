# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PathLocksResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:path_lock) { create(:path_lock, path: 'README.md', project: project) }

  let(:user) { project.first_owner }

  describe '#resolve' do
    subject(:resolve_path_locks) do
      resolve(described_class,
              obj: project, lookahead: positive_lookahead, ctx: { current_user: user }, arg_style: :internal)
    end

    context 'feature is not licensed' do
      before do
        stub_licensed_features(file_locks: false)
      end

      it { is_expected.to be_empty }
    end

    context 'feature is licensed' do
      before do
        stub_licensed_features(file_locks: true)
      end

      it { is_expected.to contain_exactly(path_lock) }

      it 'preloads users' do
        path_lock = resolve_path_locks.first

        expect(path_lock.association_cached?(:user)).to be_truthy
      end

      context 'user is unauthorized' do
        let(:user) { create(:user) }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            resolve_path_locks
          end
        end
      end
    end
  end
end
