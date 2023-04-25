# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IterationNote do
  describe '.from_event' do
    let(:author) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:noteable) { create(:issue, author: author, project: project) }
    let(:event) { create(:resource_iteration_event, issue: noteable) }

    subject { described_class.from_event(event, resource: noteable, resource_parent: project) }

    it_behaves_like 'a synthetic note', 'iteration'

    context 'with a remove iteration event' do
      let(:iteration) { create(:iteration) }
      let(:event) { create(:resource_iteration_event, action: :remove, issue: noteable, iteration: iteration) }

      it 'creates the expected note' do
        expect(subject.note).to eq("removed iteration #{iteration.to_reference}")
        expect(subject.note_html).to include('removed iteration')
        expect(subject.note_html).not_to include('changed iteration to')
        expect(subject.created_at).to eq(event.created_at)
        expect(subject.updated_at).to eq(event.created_at)
      end
    end
  end
end
