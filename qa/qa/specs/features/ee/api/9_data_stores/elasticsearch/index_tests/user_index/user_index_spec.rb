# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Data Stores', product_group: :global_search do
    describe(
      'When using advanced search API to search for a user',
      :orchestrated,
      :elasticsearch,
      :requires_admin,
      :skip_live_env
    ) do
      include_context 'advanced search active'

      let(:api_client) { Runtime::API::Client.as_admin }

      let(:user) do
        create(:user,
          api_client: api_client,
          name: 'JoeBloggs',
          username: "qa-user-name-#{SecureRandom.hex(8)}",
          first_name: 'Joe',
          last_name: 'Bloggs')
      end

      it(
        'finds the user that matches username',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/382846'
      ) do
        QA::Support::Retrier.retry_on_exception(
          max_attempts: Runtime::Search::RETRY_MAX_ITERATION,
          sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL
        ) do
          get(Runtime::Search.create_search_request(api_client, 'users', user.username).url)
          aggregate_failures do
            expect_status(QA::Support::API::HTTP_STATUS_OK)
            expect(json_body).not_to be_empty
            expect(json_body[0][:name]).to eq(user.name)
            expect(json_body[0][:username]).to eq(user.username)
          end
        end
      end
    end
  end
end
