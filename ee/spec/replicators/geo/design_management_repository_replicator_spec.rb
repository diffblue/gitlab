# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignManagementRepositoryReplicator, feature_category: :geo_replication do
  let(:model_record) { build(:design_management_repository, project: create(:project)) }

  include_examples 'a repository replicator'
  include_examples 'a verifiable replicator'
end
