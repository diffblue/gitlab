# frozen_string_literal: true

RSpec.shared_examples 'code suggestion task' do
  it 'returns valid endpoint' do
    expect(task.endpoint).to eq endpoint
  end

  it 'returns body' do
    expect(Gitlab::Json.parse(task.body)).to eq body
  end
end
