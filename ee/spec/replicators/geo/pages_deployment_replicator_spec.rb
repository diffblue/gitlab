# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PagesDeploymentReplicator do
  let(:model_record) { build(:pages_deployment) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
