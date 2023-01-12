# frozen_string_literal: true

RSpec.shared_examples 'Analytics > Value stream fixtures' do |stage_name|
  let(:stage) { group.cycle_analytics_stages.find_by(name: stage_name) }

  it "analytics/value_stream_analytics/stages/#{stage_name}/records.json" do
    get(:records, params: params.merge({ id: stage.id, value_stream_id: stage.group_value_stream_id }), format: :json)

    expect(response).to be_successful
  end

  it "analytics/value_stream_analytics/stages/#{stage_name}/median.json" do
    get(:median, params: params.merge({ id: stage.id, value_stream_id: stage.group_value_stream_id }), format: :json)

    expect(response).to be_successful
  end

  it "analytics/value_stream_analytics/stages/#{stage_name}/count.json" do
    get(:count, params: params.merge({ id: stage.id, value_stream_id: stage.group_value_stream_id }), format: :json)

    expect(response).to be_successful
  end
end
