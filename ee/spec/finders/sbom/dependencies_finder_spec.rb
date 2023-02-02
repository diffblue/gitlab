# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::DependenciesFinder, feature_category: :dependency_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:occurrences) { create_list(:sbom_occurrence, 5, project: project) }

  subject(:dependencies) { described_class.new(project).execute }

  it 'returns the dependencies associated with the project' do
    expect(dependencies).to match_array(occurrences)
  end

  context 'when occurrences exceed default page size' do
    let_it_be(:occurrences) { create_list(:sbom_occurrence, described_class::DEFAULT_PER_PAGE + 1, project: project) }

    it 'uses pagination by default' do
      expect(dependencies.size).to eq(described_class::DEFAULT_PER_PAGE)
    end
  end
end
