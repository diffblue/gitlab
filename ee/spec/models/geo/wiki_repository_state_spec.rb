# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::WikiRepositoryState, type: :model, feature_category: :geo_replication do
  subject { described_class.new(project_wiki_repository: build(:project_wiki_repository)) }

  describe 'associations' do
    it {
      is_expected
        .to belong_to(:project_wiki_repository)
        .class_name('Projects::WikiRepository')
        .inverse_of(:wiki_repository_state)
    }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_wiki_repository) }
    it { is_expected.to validate_presence_of(:verification_state) }
    it { is_expected.to validate_uniqueness_of(:project_wiki_repository) }
    it { is_expected.to validate_length_of(:verification_failure).is_at_most(255) }
  end
end
