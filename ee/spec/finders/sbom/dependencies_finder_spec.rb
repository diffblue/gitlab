# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::DependenciesFinder, feature_category: :dependency_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:occurrences) { create_list(:sbom_occurrence, 5, project: project) }

  subject(:dependencies) { described_class.new(project).execute }

  it 'returns the dependencies associated with the project ordered by id' do
    expect(dependencies).to eq(occurrences.sort_by(&:id))
  end
end
