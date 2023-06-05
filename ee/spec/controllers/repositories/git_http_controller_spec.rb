# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController, feature_category: :source_code_management do
  context 'when repository container is a group wiki' do
    include WikiHelpers

    let_it_be(:group) { create(:group, :wiki_repo) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { nil }

    before_all do
      group.add_owner(user)
    end

    before do
      stub_group_wikis(true)
    end

    it_behaves_like described_class do
      let(:container) { group.wiki }
      let(:access_checker_class) { Gitlab::GitAccessWiki }
    end
  end

  context 'git audit streaming event' do
    include GitHttpHelpers

    it_behaves_like 'sends git audit streaming event' do
      subject do
        post :git_upload_pack, params: { repository_path: "#{project.full_path}.git" }
      end
    end
  end

  context 'group IP restriction' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, :repository, group: group) }

    let(:repository_path) { "#{project.full_path}.git" }
    let(:params) { { repository_path: repository_path, service: 'git-upload-pack' } }

    before do
      stub_licensed_features(group_ip_restriction: true)
      allow(controller).to receive(:verify_workhorse_api!).and_return(true)
    end

    subject(:send_request) {  get :info_refs, params: params }

    context 'without enforced IP allowlist' do
      it 'allows the request' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with enforced IP allowlist' do
      before_all do
        create(:ip_restriction, group: group, range: '192.168.0.0/24')
      end

      context 'when IP is allowed' do
        before do
          request.env['REMOTE_ADDR'] = '192.168.0.42'
        end

        it 'allows the request' do
          send_request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when IP is not allowed' do
        before do
          request.env['REMOTE_ADDR'] = '42.42.42.42'
        end

        it 'returns unauthorized' do
          send_request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end
end
