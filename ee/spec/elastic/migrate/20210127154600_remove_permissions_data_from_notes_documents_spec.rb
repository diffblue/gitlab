# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210127154600_remove_permissions_data_from_notes_documents.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe RemovePermissionsDataFromNotesDocuments do
  it_behaves_like 'a deprecated Advanced Search migration', 20210127154600
end
