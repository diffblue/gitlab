# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210302104500_migrate_notes_to_separate_index.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe MigrateNotesToSeparateIndex do
  it_behaves_like 'a deprecated Advanced Search migration', 20210201104800
end
