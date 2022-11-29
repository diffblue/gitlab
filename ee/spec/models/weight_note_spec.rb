# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeightNote do
  let(:author) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:noteable) { create(:issue, author: author, project: project) }
  let(:event) { create(:resource_weight_event, issue: noteable) }

  subject { described_class.from_event(event, resource: noteable, resource_parent: project) }

  it_behaves_like 'a synthetic note', 'weight'

  it 'creates the expected note' do
    expect(subject.created_at).to eq(event.created_at)
    expect(subject.updated_at).to eq(event.created_at)
  end
end
