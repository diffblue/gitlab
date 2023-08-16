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

      # https://docs.gitlab.com/ee/api/code_suggestions.html#generate-code-completions-experiment
      context 'on the GitLab API with PAT auth' do
        it 'returns a suggestion', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/420973' do
          response = post(
            'https://gitlab.com/api/v4/code_suggestions/completions',
            JSON.dump(prompt_data),
            headers: {
              Authorization: "Bearer #{Resource::PersonalAccessToken.fabricate!.token}",
              'Content-Type': 'application/json'
            }
          )

          expect(response).not_to be_nil
          expect(response.code).to be(200), "Request returned (#{response.code}): `#{response}`"

          actual_response_data = parse_body(response)
          expect(actual_response_data).to match(a_hash_including(expected_response_data))
          expect(actual_response_data.dig(:choices, 0, :text).length).to be > 0, 'The suggestion should not be blank'
        end
      end
    end
  end
end
