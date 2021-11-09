# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::AppSec::Fuzzing::Coverage::CorpusesResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:corpus1) { create(:corpus, project: project) }
  let_it_be(:corpus2) { create(:corpus, project: project) }

  context 'when resolving corpuses' do
    subject { resolve_corpus }

    context 'when the corpus exists' do
      it 'finds all the corpuses' do
        expect(subject).to match_array([corpus1, corpus2])
      end
    end

    context 'when the corpus does not exists' do
      let_it_be(:project) { create(:project) }

      it { is_expected.to be_empty }
    end
  end

  private

  def resolve_corpus
    resolve(described_class, obj: project)
  end
end
