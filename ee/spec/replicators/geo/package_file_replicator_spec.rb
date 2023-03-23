# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PackageFileReplicator, feature_category: :geo_replication do
  let(:model_record) { build(:package_file, :npm) }

  include_examples 'a blob replicator'
  # TODO: Move these examples to the blob and repo strategy shared examples so
  # these get run for all Replicators.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/280768
  it_behaves_like 'a verifiable replicator'
end
