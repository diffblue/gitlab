# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230208090000_delete_removed_fields_from_users.rb')

RSpec.describe DeleteRemovedFieldsFromUsers, :elastic, :sidekiq_inline, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20230208090000
end
