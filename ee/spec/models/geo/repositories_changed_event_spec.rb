# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoriesChangedEvent, type: :model, feature_category: :geo_replication do
  describe 'relationships' do
    it { is_expected.to belong_to(:geo_node) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:geo_node) }
  end
end
