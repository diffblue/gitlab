# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CoverageFuzzingCorpus'] do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:object) { create(:corpus, project: project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:fields) { %i[id package] }

  specify { expect(described_class.graphql_name).to eq('CoverageFuzzingCorpus') }
  specify { expect(described_class.description).to eq('Corpus for a coverage fuzzing job.') }
  specify { expect(described_class).to require_graphql_authorizations(:read_coverage_fuzzing) }

  before do
    stub_licensed_features(coverage_fuzzing: true)
  end

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'id field' do
    it 'correctly resolves the field' do
      expect(resolve_field(:id, object, current_user: user)).to eq(object.to_global_id)
    end
  end

  describe 'package field' do
    it 'correctly resolves the field' do
      expect(resolve_field(:package, object, current_user: user)).to eq(object.package)
    end
  end
end
