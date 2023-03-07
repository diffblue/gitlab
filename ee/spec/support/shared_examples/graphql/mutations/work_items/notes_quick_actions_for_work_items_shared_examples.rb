# frozen_string_literal: true

RSpec.shared_examples 'work item supports weights widget updates via quick actions' do
  let(:body) { "/clear_weight" }

  before do
    noteable.update!(weight: 2)
  end

  it 'updates the work item' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.to change { noteable.weight }.from(2).to(nil)
  end
end

RSpec.shared_examples 'work item does not support weights widget updates via quick actions' do
  let(:body) { "Updating weight.\n/weight 1" }

  before do
    WorkItems::Type.default_by_type(:issue).widget_definitions
      .find_by_widget_type(:weight).update!(disabled: true)
  end

  it 'ignores the quick action' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.not_to change { noteable.weight }
  end
end

RSpec.shared_examples 'work item supports health status widget updates via quick actions' do
  let(:body) { "/health_status on_track" }

  before do
    noteable.update!(health_status: nil)
  end

  it 'updates work item health status' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.to change { noteable.health_status }.from(nil).to('on_track')
  end
end

RSpec.shared_examples 'work item does not support health status widget updates via quick actions' do
  let(:body) { "Updating health status.\n/health_status on_track" }

  before do
    WorkItems::Type.default_by_type(:issue).widget_definitions
      .find_by_widget_type(:health_status).update!(disabled: true)

    noteable.update!(health_status: nil)
  end

  it 'ignores the quick action' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      noteable.reload
    end.not_to change { noteable.health_status }
  end
end
