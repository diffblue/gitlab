# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PagesController, feature_category: :pages do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when max_pages_size param is specified' do
    let(:params) { { max_pages_size: 100 } }

    let(:request) do
      put :update, params: { namespace_id: project.namespace, project_id: project, project: params }
    end

    before do
      stub_licensed_features(pages_size_limit: true)
    end

    context 'when user is an admin' do
      let(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'updates max_pages_size' do
          request

          expect(project.reload.max_pages_size).to eq(100)
        end
      end

      context 'when admin mode is disabled' do
        it 'does not update max_pages_size' do
          request

          expect(project.reload.max_pages_size).to eq(nil)
        end
      end
    end

    context 'when user is not an admin' do
      it 'does not update max_pages_size' do
        request

        expect(project.reload.max_pages_size).to eq(nil)
      end
    end
  end
end
