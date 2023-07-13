# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeHelper, feature_category: :web_ide do
  describe '#ide_data' do
    let_it_be(:project) { build_stubbed(:project) }
    let_it_be(:user) { project.creator }
    let_it_be(:fork_info) { { ide_path: '/test/ide/path' } }

    let_it_be(:params) do
      {
        branch: 'master',
        path: 'foo/bar',
        merge_request_id: '1'
      }
    end

    let(:base_data) do
      {
        'use-new-web-ide' => 'false'
      }
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:content_security_policy_nonce).and_return('test-csp-nonce')
      allow(helper).to receive(:new_session_path).and_return('test-sign-in-path')
    end

    it 'returns hash with no code suggestions' do
      expect(helper.ide_data(project: nil, fork_info: fork_info, params: params))
        .to include(base_data)
      expect(helper.ide_data(project: nil, fork_info: fork_info, params: params))
        .not_to include(:code_suggestions_enabled)
    end

    context 'with vscode_web_ide=true' do
      let(:base_data) do
        {
          'use-new-web-ide' => 'true'
        }
      end

      before do
        stub_feature_flags(vscode_web_ide: true)
      end

      it 'returns hash with code suggestions disabled' do
        expect(helper.ide_data(project: nil, fork_info: fork_info, params: params))
          .to include(base_data)
      end

      context 'when user can access code suggestions' do
        before do
          allow(user).to receive(:can?).with(:access_code_suggestions).and_return(true)
        end

        it 'returns hash with code suggestions enabled' do
          expect(
            helper.ide_data(project: project, fork_info: nil, params: params)
          ).to include(base_data.merge(
            'code-suggestions-enabled' => 'true'
          ))
        end
      end
    end
  end
end
