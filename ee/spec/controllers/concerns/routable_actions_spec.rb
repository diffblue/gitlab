# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RoutableActions do
  controller(::ApplicationController) do
    include RoutableActions

    before_action :routable

    def routable
      @klass = params[:type].constantize
      @routable = find_routable!(params[:type].constantize, params[:id], '/')
    end

    def show
      head :ok
    end

    def create
      head :ok
    end
  end

  def request_params(routable)
    { id: routable.full_path, type: routable.class }
  end

  describe '#find_routable!' do
    describe 'when SSO enforcement prevents access' do
      let(:saml_provider) { create(:saml_provider, enforced_sso: true) }
      let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
      let(:root_group) { saml_provider.group }
      let(:user) { identity.user }

      before do
        stub_licensed_features(group_saml: true)
        sign_in(user)
      end

      shared_examples 'sso redirects' do
        it 'redirects to group sign in page' do
          get :show, params: request_params(routable)

          expect(response).to have_gitlab_http_status(:found)
          expect(response.location).to match(%r{groups/.*/-/saml/sso\?redirect=.+&token=})
        end

        it 'does not redirect on POST requests' do
          post :create, params: request_params(routable)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      describe 'for a group' do
        let(:routable) { root_group }

        include_examples 'sso redirects'
      end

      describe 'for a nested group' do
        let(:routable) { create(:group, :private, parent: root_group) }

        include_examples 'sso redirects'
      end

      describe 'for a project' do
        let(:routable) { create(:project, :private, group: root_group) }

        include_examples 'sso redirects'
      end

      describe 'for a nested project' do
        let(:routable) { create(:project, :private, group: create(:group, :private, parent: root_group)) }

        include_examples 'sso redirects'
      end
    end
  end
end
