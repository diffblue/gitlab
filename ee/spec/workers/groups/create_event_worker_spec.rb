# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CreateEventWorker, feature_category: :onboarding do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  subject(:worker) { described_class.new }

  it 'creats an event' do
    expect do
      worker.perform(group.id, user.id, :created)
    end.to change(Event, :count).by(1)
  end

  it 'passes the correct arguments' do
    expect(Event).to receive(:create!).with(
      {
        group_id: group.id,
        action: :created,
        author_id: user.id
      }
    )

    worker.perform(group.id, user.id, :created)
  end
end
