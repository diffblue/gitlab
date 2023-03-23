# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::UploadState, :geo, type: :model, feature_category: :geo_replication do
  it { is_expected.to belong_to(:upload).inverse_of(:upload_state) }
end
