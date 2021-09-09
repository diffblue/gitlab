# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ResourceEvents::SyntheticIterationNotesBuilderService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, author: user) }

    before do
      create_list(:resource_iteration_event, 3, issue: issue)

      stub_feature_flags(track_resource_iteration_change_events: false)
    end

    context 'when resource iteration events are disabled' do
      # https://gitlab.com/gitlab-org/gitlab/-/issues/212985
      it 'still builds notes for existing resource iteration events' do
        notes = described_class.new(issue, user).execute

        expect(notes.size).to eq(3)
      end
    end

    it_behaves_like 'filters by paginated notes', :resource_iteration_event
  end
end
