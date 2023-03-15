# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ResourceEvents::SyntheticIterationNotesBuilderService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, author: user) }

    before do
      create_list(:resource_iteration_event, 3, issue: issue)
    end

    it 'builds notes for existing resource iteration events' do
      notes = described_class.new(issue, user).execute

      expect(notes.size).to eq(3)
    end

    it_behaves_like 'filters by paginated notes', :resource_iteration_event
  end
end
