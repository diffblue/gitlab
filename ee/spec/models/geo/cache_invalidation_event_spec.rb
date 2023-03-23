# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::CacheInvalidationEvent, type: :model, feature_category: :geo_replication do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:key) }
  end
end
