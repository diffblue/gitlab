# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::MergeRequestDiffReplicator do
  let(:model_record) { create(:merge_request_diff, :external) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
