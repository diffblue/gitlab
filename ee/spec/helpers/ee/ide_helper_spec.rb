# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeHelper, feature_category: :web_ide do
  describe '#ide_data' do
    let_it_be(:user) { build(:user) }

    let(:params) { { learn_gitlab_source: true } }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns hash' do
      expect(helper.ide_data(project: nil, fork_info: nil, params: params))
        .to include('learn_gitlab_source' => 'true')
    end

    context 'when false source' do
      let(:params) { { learn_gitlab_source: false } }

      it 'returns hash' do
        expect(helper.ide_data(project: nil, fork_info: nil, params: params))
          .to include('learn_gitlab_source' => 'false')
      end
    end

    context 'when random source' do
      let(:params) { { learn_gitlab_source: 'random' } }

      it 'returns hash' do
        expect(helper.ide_data(project: nil, fork_info: nil, params: params))
          .to include('learn_gitlab_source' => '')
      end
    end

    context 'when no source' do
      let(:params) { {} }

      it 'returns hash' do
        expect(helper.ide_data(project: nil, fork_info: nil, params: params))
          .to include('learn_gitlab_source' => '')
      end
    end
  end
end
