# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RemoteMirrors, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :remote_mirror) }
  let_it_be(:project_setting) { create(:project_setting, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe 'POST /projects/:id/remote_mirrors' do
    let(:route) { "/projects/#{project.id}/remote_mirrors" }

    subject { post api(route, user), params: params }

    context 'when creating a remote mirror' do
      context 'with only_protected_branches and mirror_branch_regex' do
        let(:params) { { url: 'https://foo:bar@test.com', only_protected_branches: true, mirror_branch_regex: 'test' } }

        it 'returns 400 error' do
          subject
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with mirror_branch_regex' do
        let(:params) { { url: 'https://foo:bar@test.com', mirror_branch_regex: 'test' } }

        it 'succeeds' do
          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(response).to match_response_schema('remote_mirror')
          expect(json_response['mirror_branch_regex']).to eq('test')
        end
      end

      context 'when feature flag is disabled' do
        let(:params) { { url: 'https://foo:bar@test.com', mirror_branch_regex: 'test' } }

        before do
          stub_feature_flags(mirror_only_branches_match_regex: false)
        end

        it 'succeeds' do
          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(response).to match_response_schema('remote_mirror')
          mirror = RemoteMirror.find(json_response['id'])
          expect(mirror.mirror_branch_regex).to be_nil
        end
      end
    end
  end

  describe 'PUT /projects/:id/remote_mirrors/:mirror_id' do
    let(:route) { "/projects/#{project.id}/remote_mirrors/#{mirror.id}" }
    let(:mirror) { project.remote_mirrors.first }

    subject { put api(route, user), params: params }

    context 'when enabling only_protected_branches' do
      let(:params) { { only_protected_branches: true } }

      before do
        mirror.update!(mirror_branch_regex: 'test')
      end

      it 'removes mirror_branch_regex' do
        subject

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['only_protected_branches']).to eq(true)
        expect(json_response['mirror_branch_regex']).to be_nil
      end
    end

    context 'when disabling only_protected_branches' do
      let(:params) { { only_protected_branches: false } }

      context 'with only_protected_branches enabled' do
        before do
          mirror.update!(only_protected_branches: true, mirror_branch_regex: nil)
        end

        it 'disables protected branches mirroring' do
          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['only_protected_branches']).to be_falsey
          expect(json_response['mirror_branch_regex']).to be_nil
        end
      end

      context 'with only_protected_branches disabled' do
        before do
          mirror.update!(only_protected_branches: false, mirror_branch_regex: 'text')
        end

        it 'does not remove mirror_branch_regex' do
          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['only_protected_branches']).to be_falsey
          expect(json_response['mirror_branch_regex']).to eq 'text'
        end
      end
    end

    context 'when setting mirror_branch_regex' do
      let(:params) { { mirror_branch_regex: 'test' } }

      before do
        mirror.update!(only_protected_branches: true, mirror_branch_regex: nil)
      end

      it 'disables protected branches mirroring' do
        subject

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['only_protected_branches']).to be_falsey
        expect(json_response['mirror_branch_regex']).to eq('test')
      end
    end

    context 'when removing mirror_branch_regex' do
      let(:params) { { mirror_branch_regex: nil } }

      before do
        mirror.update!(only_protected_branches: false, mirror_branch_regex: 'text')
      end

      it 'succeeds' do
        subject

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['only_protected_branches']).to be_falsey
        expect(json_response['mirror_branch_regex']).to be_nil
      end
    end

    context 'when feature flag is disabled' do
      let(:params) { { mirror_branch_regex: 'text1' } }

      before do
        mirror.update!(only_protected_branches: false, mirror_branch_regex: 'text2')
        stub_feature_flags(mirror_only_branches_match_regex: false)
      end

      it 'removes mirror_branch_regex' do
        subject

        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('remote_mirror')
        mirror = RemoteMirror.find(json_response['id'])
        expect(mirror.mirror_branch_regex).to be_nil
      end
    end
  end
end
