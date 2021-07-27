# frozen_string_literal: true

RSpec.shared_examples 'Analytics > Value stream fixtures' do |stage|
  it "analytics/value_stream_analytics/stages/#{stage}/records.json" do
    stage_id = group.cycle_analytics_stages.find_by(name: stage).id
    get(:records, params: params.merge({ id: stage_id }), format: :json)

    expect(response).to be_successful
  end

  it "analytics/value_stream_analytics/stages/#{stage}/median.json" do
    stage_id = group.cycle_analytics_stages.find_by(name: stage).id
    get(:median, params: params.merge({ id: stage_id }), format: :json)

    expect(response).to be_successful
  end

  it "analytics/value_stream_analytics/stages/#{stage}/count.json" do
    stage_id = group.cycle_analytics_stages.find_by(name: stage).id
    get(:count, params: params.merge({ id: stage_id }), format: :json)

    expect(response).to be_successful
  end
end
