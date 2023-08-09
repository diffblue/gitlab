# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PagesDeploymentReplicator, feature_category: :geo_replication do
  let(:model_record) { create(:pages_deployment) }

  include_examples 'a blob replicator'
end
