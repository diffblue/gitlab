# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelLink, feature_category: :global_search do
  describe 'callback ' do
    describe 'after_destroy' do
      let_it_be(:label) { create(:label) }
      let_it_be(:issue) { create(:labeled_issue, labels: [label]) }
      let_it_be(:issue2) { create(:labeled_issue, labels: [label]) }

      it 'synchronizes elasticsearch for issues' do
        expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(issue).once
        expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(issue2).once
        label.destroy!
      end
    end
  end
end
