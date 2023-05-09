# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RoutableActions, feature_category: :system_access do
  controller(::ApplicationController) do
    include RoutableActions # rubocop:disable RSpec/DescribedClass
    skip_before_action :authenticate_user!

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
    context 'when SAML SSO is enabled for resource' do
      using RSpec::Parameterized::TableSyntax

      let(:saml_provider) { create(:saml_provider, enabled: true, enforced_sso: false) }
      let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
      let(:root_group) { saml_provider.group }
      let(:subgroup) { create(:group, parent: root_group) }
      let(:project) { create(:project, group: root_group) }
      let(:member_with_identity) { identity.user }
      let(:member_without_identity) { create(:user) }
      let(:non_member) { create(:user) }
      let(:not_signed_in_user) { nil }

      before do
        stub_licensed_features(group_saml: true)
        root_group.add_developer(member_with_identity)
        root_group.add_developer(member_without_identity)
      end

      shared_examples 'SSO Enforced' do
        it 'redirects to group SSO page on GET requests', :aggregate_failures do
          get :show, params: request_params(resource)

          expect(response).to have_gitlab_http_status(:found)
          expect(response.location).to match(%r{groups/.*/-/saml/sso\?redirect=.+&token=})
        end
      end

      shared_examples 'SSO Not enforced' do
        it 'allows to read response of GET requests' do
          get :show, params: request_params(resource)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      shared_examples 'SSO Not enforced; For signed in user, no access to the resource due to its visibility level' do
        it 'does not redirect to group SSO page on GET requests, returns not_found instead', :aggregate_failures do
          expect(resource.root_ancestor.saml_provider.enforced_sso?).to eq(false)

          get :show, params: request_params(resource)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      shared_examples 'SSO Not enforced; For not signed in user, no access to the resource due to its visibility level' do
        it 'does not redirect to group SSO page on GET requests, redirects to /users/sign_in page instead', :aggregate_failures do
          expect(resource.root_ancestor.saml_provider.enforced_sso?).to eq(false)

          get :show, params: request_params(resource)

          expect(response).to have_gitlab_http_status(:found)
          expect(response.location).to end_with('/users/sign_in')
        end
      end

      # See https://docs.gitlab.com/ee/user/group/saml_sso/#sso-enforcement
      where(:resource, :resource_visibility_level, :enforced_sso?, :user, :user_is_resource_owner?, :user_with_saml_session?, :shared_examples) do
        # Project/Group visibility: Private; Enforce SSO setting: Off

        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | true  | false | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'

        ref(:root_group) | 'private' | false | ref(:member_without_identity) | false | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_without_identity) | false | nil   | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_without_identity) | false | nil   | 'SSO Not enforced'

        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | 'SSO Not enforced; For signed in user, no access to the resource due to its visibility level'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | 'SSO Not enforced; For signed in user, no access to the resource due to its visibility level'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | 'SSO Not enforced; For signed in user, no access to the resource due to its visibility level'
        ref(:root_group) | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced; For not signed in user, no access to the resource due to its visibility level'
        ref(:subgroup)   | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced; For not signed in user, no access to the resource due to its visibility level'
        ref(:project)    | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced; For not signed in user, no access to the resource due to its visibility level'

        # Project/Group visibility: Private; Enforce SSO setting: On

        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | true  | false | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'

        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | true  | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | true  | nil   | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | true  | nil   | 'SSO Enforced'

        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Enforced'

        # Project/Group visibility: Public; Enforce SSO setting: Off

        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | true  | false | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'

        ref(:root_group) | 'public'  | false | ref(:member_without_identity) | false | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_without_identity) | false | nil   | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_without_identity) | false | nil   | 'SSO Not enforced'

        ref(:root_group) | 'public'  | false | ref(:non_member)              | nil   | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:non_member)              | nil   | nil   | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:non_member)              | nil   | nil   | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced'

        # Project/Group visibility: Public; Enforce SSO setting: On

        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | true  | false | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | true  | false | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | true  | 'SSO Not enforced'

        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | true  | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | true  | nil   | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | true  | nil   | 'SSO Enforced'

        ref(:root_group) | 'public'  | true  | ref(:non_member)              | nil   | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:non_member)              | nil   | nil   | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:non_member)              | nil   | nil   | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | 'SSO Not enforced'
      end

      with_them do
        context "when 'Enforce SSO-only authentication for web activity for this group' option is #{params[:enforced_sso?] ? 'enabled' : 'not enabled'}" do
          before do
            saml_provider.update!(enforced_sso: enforced_sso?)
          end

          context "when resource is #{params[:resource_visibility_level]}" do
            before do
              resource.update!(visibility_level: Gitlab::VisibilityLevel.string_options[resource_visibility_level])
            end

            context 'for user' do
              before do
                if user_is_resource_owner?
                  resource.root_ancestor.member(user).update_column(:access_level, Gitlab::Access::OWNER)
                end

                if user_with_saml_session?
                  Gitlab::Session.with_session(request.session) do
                    Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session
                  end
                end

                sign_in(user) if user
              end

              include_examples params[:shared_examples]
            end
          end
        end
      end
    end
  end
end
