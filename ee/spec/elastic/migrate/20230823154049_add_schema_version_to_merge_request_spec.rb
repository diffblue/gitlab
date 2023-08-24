# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230823154049_add_schema_version_to_merge_request.rb')

RSpec.describe AddSchemaVersionToMergeRequest, :elastic, feature_category: :global_search do
  let(:version) { 20230823154049 }

  include_examples 'migration adds mapping'
end
