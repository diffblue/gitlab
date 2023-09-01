# frozen_string_literal: true

RSpec.shared_examples 'security and compliance feature' do
  context 'when security and compliance disabled' do
    before do
      project.project_feature.update!(security_and_compliance_access_level: Featurable::DISABLED)
    end

    context 'when user has role that enables sufficient access' do
      before do
        group.add_developer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user does not have role that enables sufficient access' do
      before do
        group.add_guest(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    it_behaves_like "doesn't track govern usage event", 'users_visiting_security_vulnerabilities' do
      let(:request) { subject }
    end
  end

  context 'when security and compliance enabled' do
    before do
      project.project_feature.update!(security_and_compliance_access_level: Featurable::ENABLED)
    end

    context 'when user has role that enables sufficient access' do
      before do
        group.add_developer(user)
      end

      it { is_expected.not_to have_gitlab_http_status(:not_found) }
    end

    context 'when user does not have role that enables sufficient access' do
      before do
        group.add_guest(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
