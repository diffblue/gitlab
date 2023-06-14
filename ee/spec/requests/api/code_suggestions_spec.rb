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

        include_examples 'a response', 'not found' do
          let(:result) { :not_found }
          let(:body) do
            { "message" => "404 Not Found" }
          end
        end
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
                'https://gitlab.com/api/v4/code_suggestions/tokens',
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
end
