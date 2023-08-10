# frozen_string_literal: true

module QA
  # These tests require several feature flags, user settings, and instance configuration that will require substantial
  # effort to fully automate. In the meantime the following were done manually so we can run the tests against
  # gitlab.com with the `gitlab-qa` user:
  # 1. Enable the code_suggestions_completion_api feature flag
  #    ```/chatops run feature set --user=gitlab-qa code_suggestions_completion_api true```
  # 2. Enable the Code Suggestions user preference
  #    See https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html#enable-code-suggestions-for-an-individual-user
  RSpec.describe 'ModelOps', { only: :pipeline ['canary production'] } do
    include Support::API

    describe 'Code Suggestions', product_group: :ai_assisted do
      shared_examples 'returns a suggestion' do |testcase|
        let(:prompt_data) do
          {
            prompt_version: 1,
            project_path: 'gitlab-org/gitlab',
            project_id: 278964,
            current_file: {
              file_name: 'main.py',
              content_above_cursor: '\"\"\"\nTest the code suggestions API\"\"\"\n',
              content_below_cursor: '# auth'
            }
          }
        end

        let(:expected_response_data) do
          {
            id: 'id',
            model: {
              engine: 'vertex-ai',
              name: 'code-gecko',
              lang: 'python'
            },
            object: 'text_completion',
            created: anything,
            choices: [
              {
                text: anything,
                index: 0,
                finish_reason: 'length'
              }
            ]
          }
        end

        let(:auth_bearer_headers) do
          {
            Authorization: "Bearer #{token}",
            'Content-Type': 'application/json'
          }
        end

        it 'returns a suggestion', testcase: testcase do
          response = post(endpoint, JSON.dump(prompt_data), headers: headers)

          expect(response).not_to be_nil
          expect(response.code).to be(200), "Request returned (#{response.code}): `#{response}`"

          actual_response_data = parse_body(response)
          expect(actual_response_data).to match(a_hash_including(expected_response_data))
          expect(actual_response_data.dig(:choices, 0, :text).length).to be > 0, 'The suggestion should not be blank'
        end
      end

      # TODO Move these to https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions
      context 'on the model gateway' do
        # https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#authentication
        let(:endpoint) { 'https://codesuggestions.gitlab.com/v2/completions' }

        context(
          'with PAT auth',
          quarantine: {
            type: :investigating,
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/420643#note_1499921623'
          }
        ) do
          let(:headers) { auth_bearer_headers }
          let(:token) { personal_access_token }

          include_examples 'returns a suggestion', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/420971'
        end

        context 'with Code Suggestions auth' do
          let(:headers) { auth_bearer_headers.merge('X-Gitlab-Authentication-Type': 'oidc') }
          let(:token) { code_suggestions_access_token }

          include_examples 'returns a suggestion', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/420972'
        end
      end

      context 'on the GitLab API' do
        # https://docs.gitlab.com/ee/api/code_suggestions.html#generate-code-completions-experiment
        let(:endpoint) { 'https://gitlab.com/api/v4/code_suggestions/completions' }

        context 'with PAT auth' do
          let(:headers) { auth_bearer_headers }
          let(:token) { personal_access_token }

          include_examples 'returns a suggestion', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/420973'
        end
      end

      # Used by the Model Gateway to confirm if a user can use code suggestions
      # Added in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100500
      it(
        'reports user can use AI Assist',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/420974'
      ) do
        response = get('https://gitlab.com/api/v4/ml/ai-assist', headers: { 'PRIVATE-TOKEN': personal_access_token })

        expect(response).not_to be_nil
        expect(response.code).to be(200), "Request returned (#{response.code}): `#{response}`"
        expect(parse_body(response)).to match(a_hash_including(
          {
            user_is_allowed: true,
            third_party_ai_features_enabled: true
          }
        ))
      end

      # Returns the personal access token for the gitlab-qa user
      def personal_access_token
        @personal_access_token ||= Resource::PersonalAccessToken.fabricate!.token
      end

      # Returns a JWT access token
      # See https://gitlab.com/groups/gitlab-org/-/epics/10808#option-1-single-instance-token for details
      # We don't need to fetch one ourselves when using code suggestions via the GitLab API, just via the Model Gateway
      # See also https://gitlab.com/gitlab-org/gitlab/-/issues/419679
      def code_suggestions_access_token
        @code_suggestions_access_token ||= begin
          headers = {
            Authorization: "Bearer #{personal_access_token}",
            'Content-Type': 'application/json'
          }
          url = 'https://gitlab.com/api/v4/code_suggestions/tokens'
          response = post(url, nil, headers: headers)

          unless response.code == 201
            safe_response = masked_parsed_response(response, mask_secrets: [:access_token])
            raise "Failed to get code suggestions access token. " \
                  "Request returned (#{response.code}): `#{safe_response}`."
          end

          parse_body(response)[:access_token]
        end
      end
    end
  end
end
