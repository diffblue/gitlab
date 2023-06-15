# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Mentionable, feature_category: :team_planning do
  context Epic do
    describe '#store_mentions!' do
      it_behaves_like 'mentions in description', :epic
      it_behaves_like 'mentions in notes', :epic do
        let(:note) { create(:note_on_epic) }
        let(:mentionable) { note.noteable }
      end
    end

    describe 'load mentions' do
      it_behaves_like 'load mentions from DB', :epic do
        let(:note) { create(:note_on_epic) }
        let(:mentionable) { note.noteable }
      end
    end
  end
end
