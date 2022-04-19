# frozen_string_literal: true

class MigrateMergeRequestsToSeparateIndex < Elastic::Migration
  include Elastic::MigrationObsolete
end
