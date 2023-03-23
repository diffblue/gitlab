# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::UploadReplicator, feature_category: :geo_replication do
  let(:model_record) { create(:upload, :with_file) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
