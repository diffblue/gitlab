# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequestsCountResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }

    specify do
      expect(described_class).to have_nullable_graphql_type(GraphQL::Types::Int)
    end

    context 'when counting closing merge requests from a public issue' do
      let_it_be(:project) { create(:project, :repository, :public) }
      let_it_be(:issue) { create(:issue, project: project) }
      let_it_be(:merge_request) { create(:merge_requests_closing_issues, issue: issue) }

      subject { batch_sync { resolve_merge_requests_count(issue) } }

      it 'returns the count of the merge requests closing the issue' do
        expect(subject).to eq(1)
      end
    end

    context 'when attempting to view a private issue' do
      let_it_be(:private_project) { create(:project, :repository, :private) }
      let_it_be(:issue) { create(:issue, project: private_project) }

      before_all do
        create(:merge_requests_closing_issues, issue: issue)
        create(:merge_requests_closing_issues, issue: issue)
      end

      context 'when a user has permission to view the issue' do
        before do
          private_project.add_developer(user)
        end

        subject { batch_sync { resolve_merge_requests_count(issue) } }

        it 'returns the count of the merge requests closing the issue' do
          expect(subject).to eq(2)
        end
      end

      context 'when a user does not have permission to view the issue' do
        subject { batch_sync { resolve_merge_requests_count(issue) } }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end

  def resolve_merge_requests_count(obj)
    resolve(described_class, obj: obj, ctx: { current_user: user })
  end
end
