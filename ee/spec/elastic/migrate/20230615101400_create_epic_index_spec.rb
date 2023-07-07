# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230615101400_create_epic_index.rb')

RSpec.describe CreateEpicIndex, feature_category: :global_search do
  it_behaves_like 'migration creates a new index', 20230615101400, Epic
end
