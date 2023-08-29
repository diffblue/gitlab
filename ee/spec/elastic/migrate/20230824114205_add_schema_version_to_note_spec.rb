# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230824114205_add_schema_version_to_note.rb')

RSpec.describe AddSchemaVersionToNote, :elastic, feature_category: :global_search do
  let(:version) { 20230824114205 }

  include_examples 'migration adds mapping'
end
