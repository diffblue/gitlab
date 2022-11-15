# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DependencyProxyBlobReplicator do
  let(:model_record) { build(:dependency_proxy_blob) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
