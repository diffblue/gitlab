# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::TerraformStateVersionReplicator, feature_category: :geo_replication do
  let_it_be(:ci_build) { create(:ci_build) }
  let_it_be_with_reload(:terraform_state) { create(:terraform_state, project: ci_build.project) }

  let(:model_record) { build(:terraform_state_version, build: ci_build, terraform_state: terraform_state) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
