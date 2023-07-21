# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::CodeSuggestions, feature_category: :code_suggestions do
  let(:current_user) { nil }

  shared_examples 'a response' do |case_name|
    it "returns #{case_name} response", :freeze_time, :aggregate_failures do
      post_api

      expect(response).to have_gitlab_http_status(result)

      expect(json_response).to include(**body)
    end

    it "records Snowplow events" do
      post_api

      if case_name == 'successful'
        expect_snowplow_event(
          category: described_class.name,
          action: :authenticate,
          user: current_user,
          label: 'code_suggestions'
        )
      else
        expect_no_snowplow_event
      end
    end
  end

  shared_examples 'a successful response' do
    include_examples 'a response', 'successful' do
      let(:result) { :created }
      let(:body) do
        {
          'access_token' => kind_of(String),
          'expires_in' => Gitlab::CodeSuggestions::AccessToken::EXPIRES_IN,
          'created_at' => Time.now.to_i
        }
      end
    end
  end

  shared_examples 'an unauthorized response' do
    include_examples 'a response', 'unauthorized' do
      let(:result) { :unauthorized }
      let(:body) do
        { "message" => "401 Unauthorized" }
      end
    end
  end

  shared_examples 'a not found response' do
    include_examples 'a response', 'not found' do
      let(:result) { :not_found }
      let(:body) do
        { "message" => "404 Not Found" }
      end
    end
  end

  describe 'POST /code_suggestions/tokens' do
    let(:headers) { {} }
    let(:access_code_suggestions) { true }
    let(:is_gitlab_org_or_com) { true }

    subject(:post_api) { post api('/code_suggestions/tokens', current_user), headers: headers }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(an_instance_of(User), :access_code_suggestions, :global)
         .and_return(access_code_suggestions)
      allow(Gitlab).to receive(:org_or_com?).and_return(is_gitlab_org_or_com)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      include_examples 'an unauthorized response'
    end

    context 'when user is logged in' do
      let(:current_user) { create(:user) }

      context 'when API feature flag is disabled' do
        before do
          stub_feature_flags(code_suggestions_tokens_api: false)
        end

        include_examples 'a not found response'
      end

      context 'with no access to code suggestions' do
        let(:access_code_suggestions) { false }

        include_examples 'an unauthorized response'
      end

      context 'with access to code suggestions' do
        context 'when on .org or .com' do
          include_examples 'a successful response'

          it 'sets the access token realm to SaaS' do
            expect(Gitlab::CodeSuggestions::AccessToken).to receive(:new).with(
              current_user, gitlab_realm: Gitlab::CodeSuggestions::AccessToken::GITLAB_REALM_SAAS
            )

            post_api
          end

          context 'when request was proxied from self managed instance' do
            let(:headers) { { 'User-Agent' => 'gitlab-workhorse' } }

            include_examples 'a successful response'

            context 'with instance admin feature flag is disabled' do
              before do
                stub_feature_flags(code_suggestions_for_instance_admin_enabled: false)
              end

              include_examples 'an unauthorized response'
            end

            it 'sets the access token realm to self-managed' do
              expect(Gitlab::CodeSuggestions::AccessToken).to receive(:new).with(
                current_user, gitlab_realm: Gitlab::CodeSuggestions::AccessToken::GITLAB_REALM_SELF_MANAGED
              )

              post_api
            end
          end
        end

        context 'when not on .org and .com' do
          let(:is_gitlab_org_or_com) { false }
          let(:ai_access_token) { 'ai_access_token' }

          before do
            stub_ee_application_setting(ai_access_token: ai_access_token)
          end

          it 'proxy request to saas' do
            expect(Gitlab::Workhorse).to receive(:send_url)
              .with(
                "#{Gitlab::Saas.com_url}/api/v4/code_suggestions/tokens",
                include(headers: include("Authorization" => ["Bearer ai_access_token"]))
              )

            post_api
          end

          context 'when request was proxied from self managed instance' do
            let(:headers) { { 'User-Agent' => 'gitlab-workhorse' } }

            include_examples 'a response', '500' do
              let(:result) { 500 }
              let(:body) do
                { "message" => include('Proxying is only supported under .org or .com') }
              end
            end
          end
        end
      end
    end
  end

  describe 'POST /code_suggestions/completions' do
    let_it_be(:token) { 'JWTTOKEN' }
    let(:access_code_suggestions) { true }

    let(:body) do
      {
        prompt_version: 1,
        project_path: "gitlab-org/gitlab-shell",
        project_id: 33191677,
        current_file: {
          file_name: "test.py",
          content_above_cursor: "def is_even(n: int) ->",
          content_below_cursor: ""
        }
      }
    end

    subject(:post_api) do
      post api('/code_suggestions/completions', current_user), headers: headers, params: body.to_json
    end

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(current_user, :access_code_suggestions, :global)
                                          .and_return(access_code_suggestions)
    end

    shared_examples 'code completions endpoint' do
      context 'when user is not logged in' do
        let(:current_user) { nil }

        include_examples 'an unauthorized response'
      end

      context 'when user does not have access to code suggestions' do
        let(:access_code_suggestions) { false }

        include_examples 'an unauthorized response'
      end

      context 'when user is logged in' do
        let(:current_user) { create(:user) }

        it 'proxies request to code suggestions service with the auth token from the DB' do
          expect(Gitlab::HTTP).to receive(:post).with(
            "https://codesuggestions.gitlab.com/v2/completions",
            {
              body: body.to_json,
              headers: {
                'X-Gitlab-Authentication-Type' => 'oidc',
                'Authorization' => "Bearer #{token}",
                'Content-Type' => 'application/json'
              },
              open_timeout: 3,
              read_timeout: 5,
              write_timeout: 5
            }
          )

          post_api
        end

        context 'when overriding service base URL' do
          before do
            stub_env('CODE_SUGGESTIONS_BASE_URL', 'http://test.com')
          end

          it 'sends requests to this URL instead' do
            expect(Gitlab::HTTP).to receive(:post).with('http://test.com/v2/completions', an_instance_of(Hash))

            post_api
          end
        end

        context 'with telemetry headers' do
          let(:headers) do
            {
              'X-Gitlab-Authentication-Type' => 'oidc',
              'X-Gitlab-Oidc-Token' => token,
              'Content-Type' => 'application/json',
              'X-GitLab-CS-Accepts' => 'accepts',
              'X-GitLab-CS-Requests' => "requests",
              'X-GitLab-CS-Errors' => 'errors',
              'X-GitLab-CS-Custom' => 'helloworld',
              'X-GitLab-NO-Ignore' => 'ignoreme'
            }
          end

          it 'proxies appropriate headers to code suggestions service' do
            expect(Gitlab::HTTP).to receive(:post).with(
              "https://codesuggestions.gitlab.com/v2/completions",
              {
                body: body.to_json,
                headers: {
                  'X-Gitlab-Authentication-Type' => 'oidc',
                  'Authorization' => "Bearer #{token}",
                  'Content-Type' => 'application/json',
                  'X-Gitlab-Cs-Accepts' => 'accepts',
                  'X-Gitlab-Cs-Requests' => "requests",
                  'X-Gitlab-Cs-Errors' => 'errors',
                  'X-Gitlab-Cs-Custom' => 'helloworld'
                },
                open_timeout: 3,
                read_timeout: 5,
                write_timeout: 5
              }
            )

            post_api
          end
        end
      end
    end

    context 'when the instance is Gitlab.org_or_com' do
      before do
        allow(Gitlab).to receive(:org_or_com?).and_return(true)
      end

      let(:headers) do
        {
          'X-Gitlab-Authentication-Type' => 'oidc',
          'X-Gitlab-Oidc-Token' => token,
          'Content-Type' => 'application/json'
        }
      end

      context 'when project does not have active code suggestions purchase' do
        let(:current_user) { create(:user) }

        include_examples 'a not found response'
      end

      context 'when project has active code suggestions purchase' do
        let_it_be(:project) { create(:project) }
        let_it_be(:code_suggestions_add_on) { create(:gitlab_subscription_add_on) }

        let(:body) { super().merge!(project_id: project.id) }

        before do
          create(:gitlab_subscription_add_on_purchase, add_on: code_suggestions_add_on, namespace: project.namespace)
        end

        it_behaves_like 'code completions endpoint'
      end

      context 'when code_suggestions_completion_api feature flag is disabled' do
        let(:current_user) { create(:user) }

        before do
          stub_feature_flags(code_suggestions_completion_api: false)
        end

        include_examples 'a not found response'
      end

      context 'when purchase_code_suggestions feature flag is disabled' do
        let(:current_user) { create(:user) }

        before do
          stub_feature_flags(purchase_code_suggestions: false)
        end

        include_examples 'a not found response'
      end
    end

    context 'when the instance is Gitlab self-managed' do
      before do
        allow(Gitlab).to receive(:org_or_com?).and_return(false)
      end

      let(:headers) do
        {
          'X-Gitlab-Authentication-Type' => 'oidc',
          'Content-Type' => 'application/json'
        }
      end

      let_it_be(:service_access_token) { create(:service_access_token, :code_suggestions, :active, token: token) }

      it_behaves_like 'code completions endpoint'

      context 'when there is no active code suggestions token' do
        before do
          create(:service_access_token, :code_suggestions, :expired, token: token)
        end

        include_examples 'a response', 'unauthorized' do
          let(:result) { :unauthorized }
          let(:body) do
            { "message" => "401 Unauthorized" }
          end
        end
      end

      context 'when feature flag is disabled' do
        let(:current_user) { create(:user) }

        before do
          stub_feature_flags(self_managed_code_suggestions_completion_api: false)
        end

        include_examples 'a not found response'
      end
    end
  end
end
