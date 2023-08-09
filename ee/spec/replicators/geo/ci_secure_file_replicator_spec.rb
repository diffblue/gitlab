# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::CiSecureFileReplicator, feature_category: :geo_replication do
  let(:project) { create(:project) }
  let(:model_record) { create(:ci_secure_file, project: project) }

  include_examples 'a blob replicator'
end
