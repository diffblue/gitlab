# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Analytics::ProjectDeploymentFrequency, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:prod) { create(:environment, project: project, name: "prod") }
  let_it_be(:dev) { create(:environment, project: project, name: "dev") }
  let_it_be(:anonymous_user) { create(:user) }
  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }

  def make_deployment(finished_at, env)
    create(:deployment,
           status: :success,
           project: project,
           environment: env,
           finished_at: finished_at)
  end

  let_it_be(:deployment_2020_01_01) { make_deployment(DateTime.new(2020, 1, 1), prod) }
  let_it_be(:deployment_2020_01_02) { make_deployment(DateTime.new(2020, 1, 2), prod) }
  let_it_be(:deployment_2020_01_03) { make_deployment(DateTime.new(2020, 1, 3), dev) }
  let_it_be(:deployment_2020_01_04) { make_deployment(DateTime.new(2020, 1, 4), prod) }
  let_it_be(:deployment_2020_01_05) { make_deployment(DateTime.new(2020, 1, 5), prod) }

  let_it_be(:deployment_2020_02_01) { make_deployment(DateTime.new(2020, 2, 1), prod) }
  let_it_be(:deployment_2020_02_02) { make_deployment(DateTime.new(2020, 2, 2), prod) }
  let_it_be(:deployment_2020_02_03) { make_deployment(DateTime.new(2020, 2, 3), dev) }
  let_it_be(:deployment_2020_02_04) { make_deployment(DateTime.new(2020, 2, 4), prod) }
  let_it_be(:deployment_2020_02_05) { make_deployment(DateTime.new(2020, 2, 5), prod) }

  let_it_be(:deployment_2020_03_01) { make_deployment(DateTime.new(2020, 3, 1), prod) }
  let_it_be(:deployment_2020_03_02) { make_deployment(DateTime.new(2020, 3, 2), prod) }
  let_it_be(:deployment_2020_03_03) { make_deployment(DateTime.new(2020, 3, 3), dev) }
  let_it_be(:deployment_2020_03_04) { make_deployment(DateTime.new(2020, 3, 4), prod) }
  let_it_be(:deployment_2020_03_05) { make_deployment(DateTime.new(2020, 3, 5), prod) }

  let_it_be(:deployment_2020_04_01) { make_deployment(DateTime.new(2020, 4, 1), prod) }
  let_it_be(:deployment_2020_04_02) { make_deployment(DateTime.new(2020, 4, 2), prod) }
  let_it_be(:deployment_2020_04_03) { make_deployment(DateTime.new(2020, 4, 3), dev) }
  let_it_be(:deployment_2020_04_04) { make_deployment(DateTime.new(2020, 4, 4), prod) }
  let_it_be(:deployment_2020_04_05) { make_deployment(DateTime.new(2020, 4, 5), prod) }

  let(:dora4_analytics_enabled) { true }
  let(:current_user) { reporter }
  let(:params) { { from: Time.now, to: Time.now, interval: "all", environment: prod.name } }
  let(:path) { api("/projects/#{project.id}/analytics/deployment_frequency", current_user) }
  let(:request) { get path, params: params }
  let(:request_time) { nil }

  before do
    stub_licensed_features(dora4_analytics: dora4_analytics_enabled)

    if request_time
      travel_to(request_time) { request }
    else
      request
    end
  end

  context 'when user has access to the project' do
    it 'returns `ok`' do
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'with params: from 2017 to 2019' do
    let(:params) { { environment: prod.name, from: DateTime.new(2017), to: DateTime.new(2019) } }

    it 'returns `bad_request` with expected message' do
      expect(response.parsed_body).to eq({
        "message" => "400 Bad request - Date range is greater than 91 days"
      })
    end
  end

  context 'with params: from 2019 to 2017' do
    let(:params) do
      { environment: prod.name, from: DateTime.new(2019), to: DateTime.new(2017) }
    end

    it 'returns `bad_request` with expected message' do
      expect(response.parsed_body).to eq({
        "message" => "400 Bad request - Parameter `to` is before the `from` date"
      })
    end
  end

  context 'with params: from 2020/04/02 to request time' do
    let(:request_time) { DateTime.new(2020, 4, 4) }
    let(:params) { { environment: prod.name, from: DateTime.new(2020, 4, 2) } }

    it 'returns the expected deployment frequencies' do
      expect(response.parsed_body).to eq([{
        "from" => "2020-04-02",
        "to" => "2020-04-04",
        "value" => 1
      }])
    end
  end

  context 'with params: from 2020/02/01 to 2020/04/01 by all' do
    let(:params) do
      {
        environment: prod.name,
        from: DateTime.new(2020, 2, 1),
        to: DateTime.new(2020, 4, 1),
        interval: "all"
      }
    end

    it 'returns the expected deployment frequencies' do
      expect(response.parsed_body).to eq([{
          "from" => "2020-02-01",
          "to" => "2020-04-01",
          "value" => 8
        }])
    end
  end

  context 'with params: from 2020/02/01 to 2020/04/01 by month' do
    let(:params) do
      {
        environment: prod.name,
        from: DateTime.new(2020, 2, 1),
        to: DateTime.new(2020, 4, 1),
        interval: "monthly"
      }
    end

    it 'returns the expected deployment frequencies' do
      expect(response.parsed_body).to eq(
        [
          { "from" => "2020-02-01", "to" => "2020-03-01", "value" => 4 },
          { "from" => "2020-03-01", "to" => "2020-04-01", "value" => 4 }
        ])
    end
  end

  context 'with params: from 2020/02/01 to 2020/04/01 by day' do
    let(:params) do
      {
        environment: prod.name,
        from: DateTime.new(2020, 2, 1),
        to: DateTime.new(2020, 4, 1),
        interval: "daily"
      }
    end

    it 'returns the expected deployment frequencies' do
      expect(response.parsed_body).to eq(
        [
          { "from" => "2020-02-01", "to" => "2020-02-02", "value" => 1 },
          { "from" => "2020-02-02", "to" => "2020-02-03", "value" => 1 },
          { "from" => "2020-02-04", "to" => "2020-02-05", "value" => 1 },
          { "from" => "2020-02-05", "to" => "2020-02-06", "value" => 1 },
          { "from" => "2020-03-01", "to" => "2020-03-02", "value" => 1 },
          { "from" => "2020-03-02", "to" => "2020-03-03", "value" => 1 },
          { "from" => "2020-03-04", "to" => "2020-03-05", "value" => 1 },
          { "from" => "2020-03-05", "to" => "2020-03-06", "value" => 1 }
        ])
    end
  end

  context 'with params: invalid interval' do
    let(:params) do
      {
        environment: prod.name,
        from: DateTime.new(2020, 1),
        to: DateTime.new(2020, 2),
        interval: "invalid"
      }
    end

    it 'returns `bad_request`' do
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'with params: missing from' do
    let(:params) { { environment: prod.name, to: DateTime.new(2019), interval: "all" } }

    it 'returns `bad_request`' do
      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'when user does not have access to the project' do
    let(:current_user) { anonymous_user }

    it 'returns `not_found`' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when feature is not available in plan' do
    let(:dora4_analytics_enabled) { false }

    context 'when user has access to the project' do
      it 'returns `forbidden`' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user does not have access to the project' do
      let(:current_user) { anonymous_user }

      it 'returns `not_found`' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
