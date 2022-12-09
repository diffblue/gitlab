# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController, type: :request, feature_category: :source_code_management do
  include GitHttpHelpers
  include ::EE::GeoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :private) }

  let(:env) { { user: user.username, password: user.password } }
  let(:path) { "#{project.full_path}.git" }

  before do
    project.add_developer(user)
  end

  describe 'POST #git_upload_pack' do
    context 'geo pulls a personal snippet' do
      let_it_be(:snippet) { create(:personal_snippet, :repository, author: user) }
      let_it_be(:path) { "snippets/#{snippet.id}.git" }

      before do
        allow(::Gitlab::Geo::JwtRequestDecoder).to receive(:geo_auth_attempt?).and_return(true)
      end

      it 'allows access' do
        allow_any_instance_of(::Gitlab::Geo::JwtRequestDecoder).to receive(:decode).and_return({ scope: "snippets/#{snippet.id}" })

        clone_get(path, **env)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not allow access if scope is wrong' do
        allow_any_instance_of(::Gitlab::Geo::JwtRequestDecoder).to receive(:decode).and_return({ scope: "wron-scope" })

        clone_get(path, **env)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #info_refs' do
    context 'smartcard session required' do
      subject { clone_get(path, **env) }

      before do
        stub_licensed_features(smartcard_auth: true)
        stub_smartcard_setting(enabled: true, required_for_git_access: true)

        project.add_developer(user)
      end

      context 'user with a smartcard session', :clean_gitlab_redis_sessions do
        let(:session_id) { '42' }
        let(:stored_session) do
          { 'smartcard_signins' => { 'last_signin_at' => 5.minutes.ago } }
        end

        before do
          Gitlab::Redis::Sessions.with do |redis|
            redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
            redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
          end
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'user without a smartcard session' do
        it "does not allow access" do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.body).to eq('Project requires smartcard login. Please login to GitLab using a smartcard.')
        end
      end

      context 'with the setting off' do
        before do
          stub_smartcard_setting(required_for_git_access: false)
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST #git_receive_pack' do
    subject { push_post(path, **env) }

    context 'when node is a primary Geo one' do
      before do
        stub_primary_node
      end

      shared_examples 'triggers Geo' do
        it 'executes ::Gitlab::Geo::GitPushHttp' do
          expect_next_instance_of(::Gitlab::Geo::GitPushHttp) do |instance|
            expect(instance).to receive(:cache_referrer_node)
          end

          subject
        end

        it 'returns 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with projects' do
        it_behaves_like 'triggers Geo'
      end

      context 'with a project wiki' do
        let_it_be(:wiki) { create(:project_wiki, :empty_repo, project: project) }
        let_it_be(:path) { "#{wiki.full_path}.git" }

        it_behaves_like 'triggers Geo'
      end

      context 'with a group wiki' do
        include WikiHelpers

        let_it_be(:group) { create(:group, :wiki_repo) }
        let_it_be(:user) { create(:user) }

        let(:path) { "#{group.wiki.full_path}.git" }

        before_all do
          group.add_owner(user)
        end

        before do
          stub_group_wikis(true)
        end

        it_behaves_like 'triggers Geo'
      end

      context 'with a personal snippet' do
        let_it_be(:snippet) { create(:personal_snippet, :repository, author: user) }
        let_it_be(:path) { "snippets/#{snippet.id}.git" }

        it_behaves_like 'triggers Geo'
      end

      context 'with a project snippet' do
        let_it_be(:snippet) { create(:project_snippet, :repository, author: user, project: project) }
        let_it_be(:path) { "#{project.full_path}/snippets/#{snippet.id}.git" }

        it_behaves_like 'triggers Geo'
      end
    end
  end
end
