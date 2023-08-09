# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::MergeRequestDiffReplicator, feature_category: :geo_replication do
  let(:model_record) { create(:merge_request_diff, :external) }

  include_examples 'a blob replicator'
end
