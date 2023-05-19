# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::Repository, feature_category: :geo_replication do
  include EE::GeoHelpers

  describe 'associations' do
    it {
      is_expected
        .to have_one(:design_management_repository_state)
        .class_name('Geo::DesignManagementRepositoryState')
        .inverse_of(:design_management_repository)
        .autosave(false)
    }
  end

  include_examples 'a replicable model with a separate table for verification state' do
    let(:skip_unverifiable_model_record_tests) { true }
    let_it_be(:project) { create(:project_with_design) }
    let(:verifiable_model_record) do
      build(:design_management_repository, project: project)
    end

    let(:unverifiable_model_record) { nil }
  end

  it_behaves_like 'a project has a custom repo', :design_management_repository
end
