# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectWikiRepositoryState, type: :model do
  it { is_expected.to belong_to(:project).inverse_of(:wiki_repository_state) }
end
