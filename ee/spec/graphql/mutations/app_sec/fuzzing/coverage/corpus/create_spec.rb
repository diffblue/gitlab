# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AppSec::Fuzzing::Coverage::Corpus::Create do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:package) { create(:package, project: project, creator: developer) }

  let(:corpus) { AppSec::Fuzzing::Coverage::Corpus.find_by(user: developer, project: project) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: developer }, field: nil) }

  before do
    stub_licensed_features(coverage_fuzzing: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_coverage_fuzzing_corpus) }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(
        full_path: project.full_path,
        package_id: package.to_global_id
      )
    end

    context 'when the feature is licensed' do
      context 'when the user can create a corpus' do
        it 'returns the corpus' do
          expect(resolve[:corpus]).to eq(corpus)
        end
      end
    end
  end
end
