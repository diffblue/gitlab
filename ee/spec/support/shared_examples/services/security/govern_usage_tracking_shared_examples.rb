# frozen_string_literal: true

RSpec.shared_examples_for 'tracks govern usage event' do |event_name|
  it 'tracks unique event' do
    # allow other method calls in addition to the expected one
    allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(event_name, values: user.id)

    request
  end
end

RSpec.shared_examples_for "doesn't track govern usage event" do |event_name|
  it "doesn't tracks event" do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(event_name, any_args)

    request
  end
end

RSpec.shared_examples_for 'tracks govern usage service event' do |event_name|
  include_examples 'tracks govern usage event', event_name do
    let(:request) { execute }
  end
end

RSpec.shared_examples_for "doesn't track govern usage service event" do |event_name|
  include_examples "doesn't track govern usage event", event_name do
    let(:request) { execute }
  end
end
