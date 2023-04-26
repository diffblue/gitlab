# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::DomainVerificationController, type: :request,
                                                               feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, path: 'my.project', pages_https_only: false, group: group) }

  let_it_be(:domain) do
    create(:pages_domain, :without_key, :without_certificate, domain: 'www.domain.test', project: project)
  end

  let_it_be(:domain_secure) { create(:pages_domain, domain: 'ssl.domain.test', project: project) }
  let_it_be(:domain_with_letsencrypt) do
    create(:pages_domain, :letsencrypt, domain: 'letsencrypt.domain.test', project: project)
  end

  let(:domain_params) { { domain: 'www.other-domain.test' } }

  let(:domain_secure_params) do
    build(:pages_domain, domain: 'ssl.other-domain.test', project: project)
      .slice(:domain, :user_provided_certificate, :user_provided_key)
  end

  let(:domain_secure_key_missmatch_params) do
    build(:pages_domain, :with_trusted_chain, project: project)
      .slice(:domain, :user_provided_certificate, :user_provided_key)
  end

  let(:domain_secure_missing_chain_params) do
    build(:pages_domain, :with_missing_chain, project: project).slice(:user_provided_certificate)
  end

  let(:domain_with_letsencrypt_params) do
    build(:pages_domain, :without_key, :without_certificate, domain: 'www.other-domain.test', auto_ssl_enabled: true)
      .slice(:domain, :auto_ssl_enabled)
  end

  let(:access_level) { :owner }

  before do
    stub_licensed_features(domain_verification: true)
    stub_feature_flags(domain_verification_operation: true)
    group.add_member(user, access_level)

    sign_in(user)
  end

  shared_examples 'renders 404 when domain_verification is unavailable' do
    context "when domain_verification is unavailable" do
      before do
        stub_licensed_features(domain_verification: false)
      end

      it "renders 404" do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'renders 404 when domain_verification_operation is unavailable' do
    context "when domain domain_verification_operation is unavailable" do
      before do
        stub_feature_flags(domain_verification_operation: false)
      end

      it "renders 404" do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'renders 404' do
    it "renders 404" do
      subject
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /groups/:group_id/-/settings/domain_verification', :saas do
    subject { get group_settings_domain_verification_index_path(group) }

    context 'when domain verification is available' do
      context 'when the user is an owner' do
        it 'renders index with 200 status code' do
          subject
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
        end

        context 'when subgroup' do
          let(:group) { create(:group, parent: create(:group)) }

          it_behaves_like 'renders 404'
        end
      end

      context 'when user is not owner' do
        let(:access_level) { :maintainer }

        it_behaves_like 'renders 404'
      end
    end

    it_behaves_like 'renders 404 when domain_verification is unavailable'
  end

  describe 'GET /groups/:group_id/-/settings/domain_verification/new', :saas do
    subject { get new_group_settings_domain_verification_path(group) }

    context 'when domain_verification_operation is enabled' do
      it "render the 'new' page" do
        subject
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('new')
      end
    end

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end

  describe 'POST /groups/:group_id/-/settings/domain_verification', :saas do
    let(:params) { { pages_domain: domain_params.merge(project_id: project.id) } }
    let(:params_without_project_id) { { pages_domain: domain_params } }
    let(:params_secure) { { pages_domain: domain_secure_params.merge(project_id: project.id) } }
    let(:params_secure_without_key) do
      { pages_domain: domain_secure_params.except(:user_provided_key).merge(project_id: project.id) }
    end

    let(:params_secure_key_missmatch) do
      { pages_domain: domain_secure_key_missmatch_params.merge(project_id: project.id) }
    end

    let(:params_with_letsencrypt) { { pages_domain: domain_with_letsencrypt_params.merge(project_id: project.id) } }

    it 'creates a new domain', :aggregate_failures do
      expect { post group_settings_domain_verification_index_path(group), params: params }
        .to publish_event(PagesDomains::PagesDomainCreatedEvent)
        .with(
          project_id: project.id,
          namespace_id: project.namespace.id,
          root_namespace_id: project.root_namespace.id,
          domain_id: kind_of(Numeric),
          domain: domain_params[:domain]
        )

      domain = PagesDomain.find_by(domain: domain_params[:domain])

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_path(group, domain))
      expect(domain.project).to eq(project)
      expect(domain.domain).to eq(domain_params[:domain])
      expect(domain.certificate).to be_nil
      expect(domain.key).to be_nil
      expect(domain.auto_ssl_enabled).to be false
      expect(flash[:notice]).to eq(s_('DomainVerification|Domain was added'))
    end

    it "fails to create domain without project_id" do
      post group_settings_domain_verification_index_path(group), params: params_without_project_id

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'creates a new secure domain', :aggregate_failures do
      post group_settings_domain_verification_index_path(group), params: params_secure
      domain = PagesDomain.find_by(domain: domain_secure_params[:domain])

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_path(group, domain))
      expect(domain.project).to eq(project)
      expect(domain.domain).to eq(domain_secure_params[:domain])
      expect(domain.certificate).to eq(domain_secure_params[:user_provided_certificate])
      expect(domain.key).to eq(domain_secure_params[:user_provided_key])
      expect(domain.auto_ssl_enabled).to be false
    end

    it 'creates domain with letsencrypt enabled', :aggregate_failures do
      post group_settings_domain_verification_index_path(group), params: params_with_letsencrypt
      domain = PagesDomain.find_by(domain: domain_with_letsencrypt_params[:domain])

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_path(group, domain))
      expect(domain.project).to eq(project)
      expect(domain.domain).to eq(domain_with_letsencrypt_params[:domain])
      expect(domain.auto_ssl_enabled).to be true
    end

    it 'fails to create domain without key' do
      post group_settings_domain_verification_index_path(group), params: params_secure_without_key

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'fails to create domain with key missmatch' do
      post group_settings_domain_verification_index_path(group), params: params_secure_key_missmatch

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    subject { post group_settings_domain_verification_index_path(group), params: params }

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end

  describe 'GET /groups/:group_id/-/settings/domain_verification/:domain', :saas do
    it 'returns domain', :aggregate_failures do
      get group_settings_domain_verification_path(group, domain)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include(domain.domain)
    end

    it 'returns domain with a certificate', :aggregate_failures do
      get group_settings_domain_verification_path(group, domain_secure)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include(domain_secure.domain)
    end

    it 'returns domain with letsencrypt', :aggregate_failures do
      get group_settings_domain_verification_path(group, domain_with_letsencrypt)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include(domain_with_letsencrypt.domain)
    end

    subject { get group_settings_domain_verification_path(group, domain) }

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end

  describe 'PUT /groups/:group_id/-/settings/domain_verification/:domain', :saas do
    let(:params_secure) { { pages_domain: domain_secure_params.slice(:user_provided_certificate, :user_provided_key) } }
    let(:params_secure_nokey) { { pages_domain: domain_secure_params.slice(:user_provided_certificate) } }
    let(:params_remove_certificate) do
      { pages_domain: { auto_ssl_enabled: true, user_provided_certificate: nil, user_provided_key: nil } }
    end

    it 'updates pages domain removing certificate', :aggregate_failures do
      put group_settings_domain_verification_path(group, domain_secure), params: params_remove_certificate

      domain_secure.reload
      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_index_path(group))
      expect(domain_secure.certificate).to be_nil
      expect(domain_secure.key).to be_nil
      expect(domain_secure.auto_ssl_enabled).to be true
      expect(flash[:notice]).to eq(s_('DomainVerification|Domain was updated'))
    end

    it 'publishes PagesDomainUpdatedEvent event' do
      expect do
        put group_settings_domain_verification_path(group, domain_secure), params: params_remove_certificate
      end.to publish_event(PagesDomains::PagesDomainUpdatedEvent)
          .with(
            project_id: project.id,
            namespace_id: project.namespace.id,
            root_namespace_id: project.root_namespace.id,
            domain_id: domain_secure.id,
            domain: domain_secure.domain
          )
    end

    it 'updates pages domain adding certificate', :aggregate_failures do
      put group_settings_domain_verification_path(group, domain), params: params_secure

      domain.reload

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_index_path(group))
      expect(domain.certificate).to eq(domain_secure_params[:user_provided_certificate])
      expect(domain.key).to eq(domain_secure_params[:user_provided_key])
    end

    it 'updates pages domain enabling letsencrypt', :aggregate_failures do
      put group_settings_domain_verification_path(group, domain), params: { pages_domain: { auto_ssl_enabled: true } }

      domain.reload
      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_index_path(group))
      expect(domain.auto_ssl_enabled).to be true
    end

    it 'updates pages domain disabling letsencrypt and adding certificate', :aggregate_failures do
      put group_settings_domain_verification_path(group, domain_with_letsencrypt), params: { pages_domain:
        domain_secure_params.slice(:user_provided_certificate, :user_provided_key).merge(auto_ssl_enabled: false) }

      domain_with_letsencrypt.reload
      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_index_path(group))
      expect(domain_with_letsencrypt.auto_ssl_enabled).to be false
      expect(domain_with_letsencrypt.key).to eq(domain_secure_params[:user_provided_key])
      expect(domain_with_letsencrypt.certificate).to eq(domain_secure_params[:user_provided_certificate])
    end

    context 'with invalid params' do
      it 'fails to update pages domain adding certificate without key' do
        put group_settings_domain_verification_path(group, domain), params: params_secure_nokey

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not publish PagesDomainUpdatedEvent event' do
        expect { put group_settings_domain_verification_path(group, domain), params: params_secure_nokey }
          .not_to publish_event(PagesDomains::PagesDomainUpdatedEvent)
      end

      it 'fails to update pages domain adding certificate with missing chain' do
        put group_settings_domain_verification_path(group, domain), params: {
          pages_domain: domain_secure_missing_chain_params.slice(:user_provided_certificate)
        }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'fails to update pages domain with key missmatch' do
        put group_settings_domain_verification_path(group, domain), params: {
          pages_domain: domain_secure_key_missmatch_params.slice(:user_provided_certificate, :user_provided_key)
        }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    subject { put group_settings_domain_verification_path(group, domain_secure), params: {} }

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end

  describe 'DELETE /groups/:group_id/-/settings/domain_verification/:domain', :saas do
    subject { delete group_settings_domain_verification_path(group, domain) }

    it 'deletes a pages domain' do
      expect { subject }.to change { PagesDomain.count }.by(-1)
        .and publish_event(PagesDomains::PagesDomainDeletedEvent)
        .with(
          project_id: project.id,
          namespace_id: project.namespace.id,
          root_namespace_id: project.root_namespace.id,
          domain_id: domain.id,
          domain: domain.domain
        )

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_index_path(group))
      expect(flash[:notice]).to eq(s_('DomainVerification|Domain was removed'))
    end

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end

  describe "POST /groups/:group_id/-/settings/domain_verification/:domain/verify", :saas do
    subject { post verify_group_settings_domain_verification_path(group, domain_secure) }

    it "call VerifyPagesDomainService success" do
      expect_next_instance_of(VerifyPagesDomainService) do |instance|
        expect(instance).to receive(:execute).and_return({ status: :success })
      end

      subject

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_path(group, domain_secure))
      expect(flash[:notice]).to eq(s_('DomainVerification|Successfully verified domain ownership'))
    end

    it "call VerifyPagesDomainService error" do
      expect_next_instance_of(VerifyPagesDomainService) do |instance|
        expect(instance).to receive(:execute).and_return({ status: :error })
      end

      subject

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_path(group, domain_secure))
      expect(flash[:alert]).to eq(s_('DomainVerification|Failed to verify domain ownership'))
    end

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end

  describe "POST /groups/:group_id/-/settings/domain_verification/:domain/retry_auto_ssl", :saas do
    subject { post retry_auto_ssl_group_settings_domain_verification_path(group, domain_with_letsencrypt) }

    it "call PagesDomains::RetryAcmeOrderService" do
      expect_next_instance_of(PagesDomains::RetryAcmeOrderService) do |instance|
        expect(instance).to receive(:execute).and_call_original
      end

      subject

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_path(group, domain_with_letsencrypt))
    end

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end

  describe "DELETE /groups/:group_id/-/settings/domain_verification/:domain/clean_certificate", :saas do
    subject { delete clean_certificate_group_settings_domain_verification_path(group, domain_secure) }

    it 'remove domain certificate', :aggregate_failures do
      subject

      domain_secure.reload
      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(group_settings_domain_verification_path(group, domain_secure))
      expect(domain_secure.certificate).to be_nil
      expect(domain_secure.key).to be_nil
    end

    it_behaves_like 'renders 404 when domain_verification is unavailable'
    it_behaves_like 'renders 404 when domain_verification_operation is unavailable'
  end
end
