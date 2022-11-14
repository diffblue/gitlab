# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::WikiRepository do
  describe 'associations' do
    it {
      is_expected
        .to have_one(:wiki_repository_state)
        .class_name('Geo::ProjectWikiRepositoryState')
        .inverse_of(:project_wiki_repository)
        .autosave(false)
    }
  end
end
