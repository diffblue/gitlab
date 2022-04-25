# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210128163600_add_permissions_data_to_notes_documents.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe AddPermissionsDataToNotesDocuments do
  it_behaves_like 'a deprecated Advanced Search migration', 20210128163600
end
