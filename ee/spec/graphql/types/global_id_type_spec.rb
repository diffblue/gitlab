# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::GlobalIDType do
  context 'where we declare an argument as GlobalIDType[a] where a is prepended in EE' do
    def query(doc, vars)
      GraphQL::Query.new(GitlabSchema, document: doc, context: {}, variables: vars)
    end

    def run_query(gql_query, vars)
      query(GraphQL.parse(gql_query), vars).result
    end

    let_it_be(:iteration) { create(:iteration) }

    shared_examples 'a working query' do
      it 'returns a successful response' do
        res = run_query(document, 'iterationId' => iteration.to_global_id.to_s)

        expect(res['errors']).to be_blank
        expect(res.dig('data', 'iteration')).to eq(
          'iid' => iteration.iid.to_s,
          'id' => iteration.to_global_id.to_s
        )
      end
    end

    context 'when the argument is declared by the client as IterationID' do
      let(:document) do
        <<-GRAPHQL
        query($iterationId: IterationID!) {
          iteration(id: $iterationId) {
            id, iid
          }
        }
        GRAPHQL
      end

      it_behaves_like 'a working query'
    end

    context 'when the argument is declared by the client as EEIterationID' do
      let(:document) do
        <<-GRAPHQL
        query($iterationId: EEIterationID!) {
          iteration(id: $iterationId) {
            id, iid
          }
        }
        GRAPHQL
      end

      it_behaves_like 'a working query'
    end
  end
end
