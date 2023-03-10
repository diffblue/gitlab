# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DependencyProxyManifestReplicator, feature_category: :geo_replication do
  let(:model_record) { build(:dependency_proxy_manifest) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
