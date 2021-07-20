# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::UserDiscussionsCountResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:private_project) { create(:project, :repository, :private) }

    specify do
      expect(described_class).to have_nullable_graphql_type(GraphQL::Types::Int)
    end

    context 'when counting discussions from an epic' do
      let_it_be(:epic) { create(:epic) }
      let_it_be(:private_epic) { create(:epic, group: create(:group, :private)) }
      let_it_be(:public_discussions) { create_list(:discussion_note, 2, noteable: epic) }
      let_it_be(:system_note) { create(:discussion_note, system: true, noteable: epic) }
      let_it_be(:private_discussions) { create_list(:discussion_note, 3, noteable: private_epic) }

      before do
        stub_licensed_features(epics: true)
      end

      context 'when counting discussions from a public epic' do
        subject { batch_sync { resolve_user_discussions_count(epic) } }

        it 'returns the number of non-system discussions for the epic' do
          expect(subject).to eq(2)
        end
      end

      context 'when a user has permission to view discussions' do
        before do
          private_epic.group.add_developer(user)
        end

        subject { batch_sync { resolve_user_discussions_count(private_epic) } }

        it 'returns the number of discussions for the issue' do
          expect(subject).to eq(3)
        end
      end

      context 'when a user does not have permission to view discussions' do
        subject { batch_sync { resolve_user_discussions_count(private_epic) } }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end

  def resolve_user_discussions_count(obj)
    resolve(described_class, obj: obj, ctx: { current_user: user })
  end
end
