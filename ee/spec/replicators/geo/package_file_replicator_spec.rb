# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PackageFileReplicator, feature_category: :geo_replication do
  let(:model_record) { build(:package_file, :npm) }

  include_examples 'a blob replicator'
end
