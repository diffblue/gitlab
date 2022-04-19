# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20201123123400_migrate_issues_to_separate_index.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe MigrateIssuesToSeparateIndex do
  it_behaves_like 'a deprecated Advanced Search migration', 20201123123400
end
