# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignManagementRepositoryState, type: :model, feature_category: :geo_replication do
  subject { described_class.new(design_management_repository: create(:design_management_repository)) }

  it {
    is_expected
      .to belong_to(:design_management_repository)
      .class_name('::DesignManagement::Repository')
      .inverse_of(:design_management_repository_state)
  }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:design_management_repository) }
    it { is_expected.to validate_presence_of(:verification_state) }
    it { is_expected.to validate_length_of(:verification_failure).is_at_most(255) }
  end
end
