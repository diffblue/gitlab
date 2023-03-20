# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Vulnerabilities, feature_category: :vulnerability_management do
  include AccessMatchersForRequest

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let(:comment) { "wheee" }
  let_it_be(:user) { create(:user) }

  let(:project_vulnerabilities_path) { "/projects/#{project.id}/vulnerabilities" }

  describe 'GET /projects/:id/vulnerabilities' do
    let_it_be(:project) { create(:project, :with_vulnerabilities) }

    subject(:get_vulnerabilities) { get api(project_vulnerabilities_path, user) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'returns all vulnerabilities of a project', :aggregate_failures do
        get_vulnerabilities

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/vulnerabilities', dir: 'ee')
        expect(response.headers['X-Total']).to eq project.vulnerabilities.count.to_s
      end

      context 'with pagination' do
        let(:project_vulnerabilities_path) { "#{super()}?page=3&per_page=1" }

        it 'paginates the vulnerabilities according to the pagination params', :aggregate_failures do
          low_severity_vulnerability = create(:vulnerability, :with_finding, project: project, severity: :low)

          get_vulnerabilities

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.map { |v| v['id'] }).to contain_exactly(low_severity_vulnerability.id)
        end
      end

      it_behaves_like 'forbids access to vulnerability API endpoint in case of disabled features'
    end

    describe 'permissions', :enable_admin_mode do
      it { expect { get_vulnerabilities }.to be_allowed_for(:admin) }
      it { expect { get_vulnerabilities }.to be_allowed_for(:owner).of(project) }
      it { expect { get_vulnerabilities }.to be_allowed_for(:maintainer).of(project) }
      it { expect { get_vulnerabilities }.to be_allowed_for(:developer).of(project) }
      it { expect { get_vulnerabilities }.to be_allowed_for(:auditor) }

      it { expect { get_vulnerabilities }.to be_denied_for(:reporter).of(project) }
      it { expect { get_vulnerabilities }.to be_denied_for(:guest).of(project) }
      it { expect { get_vulnerabilities }.to be_denied_for(:anonymous) }
    end
  end

  describe 'GET /vulnerabilities/:id' do
    let_it_be(:project) { create(:project, :with_vulnerabilities) }
    let_it_be(:vulnerability) { project.vulnerabilities.first }

    let(:vulnerability_id) { vulnerability.id }

    subject(:get_vulnerability) { get api("/vulnerabilities/#{vulnerability_id}", user) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'returns the desired vulnerability', :aggregate_failures do
        get_vulnerability

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')
        expect(json_response['id']).to eq vulnerability_id
      end

      it 'returns the desired findings', :aggregate_failures do
        get_vulnerability

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')
        expect(json_response['finding']['id']).to eq vulnerability.finding.id
      end

      it_behaves_like 'responds with "not found" for an unknown vulnerability ID'
      it_behaves_like 'forbids access to vulnerability API endpoint in case of disabled features'
    end

    describe 'permissions', :enable_admin_mode do
      it { expect { get_vulnerability }.to be_allowed_for(:admin) }
      it { expect { get_vulnerability }.to be_allowed_for(:owner).of(project) }
      it { expect { get_vulnerability }.to be_allowed_for(:maintainer).of(project) }
      it { expect { get_vulnerability }.to be_allowed_for(:developer).of(project) }
      it { expect { get_vulnerability }.to be_allowed_for(:auditor) }

      it { expect { get_vulnerability }.to be_denied_for(:reporter).of(project) }
      it { expect { get_vulnerability }.to be_denied_for(:guest).of(project) }
      it { expect { get_vulnerability }.to be_denied_for(:anonymous) }
    end
  end

  describe 'POST /projects/:id/vulnerabilities' do
    let_it_be(:project) { create(:project) }

    let(:finding) { create(:vulnerabilities_finding, project: project) }
    let(:finding_id) { finding.id }
    let(:expected_error_messages) { { 'base' => ['finding is not found or is already attached to a vulnerability'] } }

    subject(:create_vulnerability) { post api(project_vulnerabilities_path, user), params: { finding_id: finding_id } }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'creates a vulnerability from finding and attaches it to the vulnerability', :aggregate_failures do
        expect { subject }.to change { project.vulnerabilities.count }.by(1)
        expect(project.vulnerabilities.last).to(
          have_attributes(
            author: user,
            title: finding.name,
            state: 'detected',
            severity: finding.severity,
            severity_overridden: false,
            confidence: finding.confidence,
            confidence_overridden: false,
            report_type: finding.report_type
          ))

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')
      end

      context 'when finding id is unknown' do
        let(:finding_id) { 0 }

        it 'responds with expected error', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(expected_error_messages)
        end
      end

      context 'when a vulnerability already exists for a specific finding' do
        before do
          create(:vulnerability, findings: [finding], project: finding.project)
        end

        it 'rejects creation of a new vulnerability from this finding', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(expected_error_messages)
        end
      end

      it_behaves_like 'forbids access to vulnerability API endpoint in case of disabled features'
    end

    describe 'permissions', :enable_admin_mode do
      it { expect { create_vulnerability }.to be_allowed_for(:admin) }
      it { expect { create_vulnerability }.to be_allowed_for(:owner).of(project) }
      it { expect { create_vulnerability }.to be_allowed_for(:maintainer).of(project) }
      it { expect { create_vulnerability }.to be_allowed_for(:developer).of(project) }

      it { expect { create_vulnerability }.to be_denied_for(:auditor) }
      it { expect { create_vulnerability }.to be_denied_for(:reporter).of(project) }
      it { expect { create_vulnerability }.to be_denied_for(:guest).of(project) }
      it { expect { create_vulnerability }.to be_denied_for(:anonymous) }
    end
  end

  describe 'POST /vulnerabilities:id/dismiss' do
    before do
      create_list(:vulnerabilities_finding, 2, vulnerability: vulnerability, project: vulnerability.project)
    end

    let_it_be(:project) { create(:project, :with_vulnerabilities) }

    let(:vulnerability) { project.vulnerabilities.first }
    let(:vulnerability_id) { vulnerability.id }

    subject(:dismiss_vulnerability) { post api("/vulnerabilities/#{vulnerability_id}/dismiss", user) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      context 'when deprecate_vulnerabilities_feedback is disabled' do
        before do
          stub_feature_flags(deprecate_vulnerabilities_feedback: false)
        end

        it 'dismisses a vulnerability and its associated findings', :aggregate_failures do
          freeze_time do
            dismiss_vulnerability

            expect(response).to have_gitlab_http_status(:created)
            expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')

            expect(vulnerability.reload).to(
              have_attributes(state: 'dismissed', dismissed_by: user, dismissed_at: be_like_time(Time.current)))
            expect(vulnerability.findings).to all have_vulnerability_dismissal_feedback
          end
        end
      end

      it_behaves_like 'responds with "not found" for an unknown vulnerability ID'

      context 'when there is a dismissal error' do
        before do
          Grape::Endpoint.before_each do |endpoint|
            allow(endpoint).to receive(:find_vulnerability!).and_wrap_original do |method, *args|
              vulnerability = method.call(*args)

              errors = ActiveModel::Errors.new(vulnerability)
              errors.add(:base, 'something went wrong')

              allow(vulnerability).to receive(:valid?).and_return(false)
              allow(vulnerability).to receive(:errors).and_return(errors)

              vulnerability
            end
          end
        end

        after do
          # resetting according to the https://github.com/ruby-grape/grape#stubbing-helpers
          Grape::Endpoint.before_each nil
        end

        it 'responds with error', :aggregate_failures do
          dismiss_vulnerability

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('base' => ['something went wrong'])
        end
      end

      context 'if a vulnerability is already dismissed' do
        let(:vulnerability) { create(:vulnerability, :with_findings, :dismissed, project: project) }

        it 'responds with 304 Not Modified' do
          dismiss_vulnerability

          expect(response).to have_gitlab_http_status(:not_modified)
        end
      end

      it_behaves_like 'forbids access to vulnerability API endpoint in case of disabled features'
    end

    describe 'permissions', :enable_admin_mode do
      it { expect { dismiss_vulnerability }.to be_allowed_for(:admin) }
      it { expect { dismiss_vulnerability }.to be_allowed_for(:owner).of(project) }
      it { expect { dismiss_vulnerability }.to be_allowed_for(:maintainer).of(project) }
      it { expect { dismiss_vulnerability }.to be_allowed_for(:developer).of(project) }

      it { expect { dismiss_vulnerability }.to be_denied_for(:auditor) }
      it { expect { dismiss_vulnerability }.to be_denied_for(:reporter).of(project) }
      it { expect { dismiss_vulnerability }.to be_denied_for(:guest).of(project) }
      it { expect { dismiss_vulnerability }.to be_denied_for(:anonymous) }
    end
  end

  describe 'POST /vulnerabilities/:id/resolve' do
    before do
      create_list(:vulnerabilities_finding, 2, vulnerability: vulnerability)
    end

    let_it_be(:project) { create(:project, :with_vulnerabilities) }

    let(:vulnerability) { project.vulnerabilities.first }
    let(:vulnerability_id) { vulnerability.id }

    subject(:resolve_vulnerability) { post api("/vulnerabilities/#{vulnerability_id}/resolve", user) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'resolves a vulnerability and its associated findings', :aggregate_failures do
        freeze_time do
          resolve_vulnerability

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')

          expect(vulnerability.reload).to(
            have_attributes(state: 'resolved', resolved_by: user, resolved_at: be_like_time(Time.current)))
          expect(vulnerability.findings).to all have_attributes(state: 'resolved')
        end
      end

      context 'with a comment' do
        let(:comment) { 'Vulnerability Resolved' }

        subject(:resolve_vulnerability) do
          post api("/vulnerabilities/#{vulnerability_id}/resolve", user), params: { comment: comment }
        end

        it 'adds the comment to the vulnerability state transition', :aggregate_failures do
          resolve_vulnerability

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')

          expect(vulnerability.reload.state_transitions.last.comment).to eq comment
        end
      end

      it_behaves_like 'responds with "not found" for an unknown vulnerability ID'

      context 'when the vulnerability is already resolved' do
        let(:vulnerability) { create(:vulnerability, :with_findings, :resolved, project: project) }

        it 'responds with 304 Not Modified response' do
          resolve_vulnerability

          expect(response).to have_gitlab_http_status(:not_modified)
        end
      end

      it_behaves_like 'forbids access to vulnerability API endpoint in case of disabled features'
    end

    describe 'permissions', :enable_admin_mode do
      it { expect { resolve_vulnerability }.to be_allowed_for(:admin) }
      it { expect { resolve_vulnerability }.to be_allowed_for(:owner).of(project) }
      it { expect { resolve_vulnerability }.to be_allowed_for(:maintainer).of(project) }
      it { expect { resolve_vulnerability }.to be_allowed_for(:developer).of(project) }

      it { expect { resolve_vulnerability }.to be_denied_for(:auditor) }
      it { expect { resolve_vulnerability }.to be_denied_for(:reporter).of(project) }
      it { expect { resolve_vulnerability }.to be_denied_for(:guest).of(project) }
      it { expect { resolve_vulnerability }.to be_denied_for(:anonymous) }
    end
  end

  describe 'POST /vulnerabilities/:id/confirm' do
    before do
      create_list(:vulnerabilities_finding, 2, vulnerability: vulnerability)
    end

    let_it_be(:project) { create(:project, :with_vulnerabilities) }

    let(:vulnerability) { project.vulnerabilities.first }
    let(:vulnerability_id) { vulnerability.id }

    subject(:confirm_vulnerability) do
      post(
        api("/vulnerabilities/#{vulnerability_id}/confirm", user),
        params: { comment: comment }
      )
    end

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'confirms a vulnerability and its associated findings', :aggregate_failures do
        freeze_time do
          confirm_vulnerability

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')

          expect(vulnerability.reload).to(
            have_attributes(state: 'confirmed', confirmed_by: user, confirmed_at: be_like_time(Time.current)))
          expect(vulnerability.findings).to all have_attributes(state: 'confirmed')
          expect(vulnerability.state_transitions.last.comment).to eq(comment)
        end
      end

      it_behaves_like 'responds with "not found" for an unknown vulnerability ID'

      context 'when the vulnerability is already confirmed' do
        let(:vulnerability) { create(:vulnerability, :with_findings, :confirmed, project: project) }

        it 'responds with 304 Not Modified response' do
          confirm_vulnerability

          expect(response).to have_gitlab_http_status(:not_modified)
        end
      end

      it_behaves_like 'forbids access to vulnerability API endpoint in case of disabled features'
    end

    describe 'permissions', :enable_admin_mode do
      it { expect { confirm_vulnerability }.to be_allowed_for(:admin) }
      it { expect { confirm_vulnerability }.to be_allowed_for(:owner).of(project) }
      it { expect { confirm_vulnerability }.to be_allowed_for(:maintainer).of(project) }
      it { expect { confirm_vulnerability }.to be_allowed_for(:developer).of(project) }

      it { expect { confirm_vulnerability }.to be_denied_for(:auditor) }
      it { expect { confirm_vulnerability }.to be_denied_for(:reporter).of(project) }
      it { expect { confirm_vulnerability }.to be_denied_for(:guest).of(project) }
      it { expect { confirm_vulnerability }.to be_denied_for(:anonymous) }
    end
  end

  describe 'POST /vulnerabilities:id/revert' do
    before do
      create_list(:vulnerabilities_finding, 2, vulnerability: vulnerability, project: vulnerability.project)
    end

    let_it_be(:project) { create(:project) }
    let_it_be(:vulnerability) { create(:vulnerability, :with_findings, :dismissed, project: project) }

    let(:vulnerability_id) { vulnerability.id }

    subject(:revert_vulnerability_to_detected) do
      post(
        api("/vulnerabilities/#{vulnerability_id}/revert", user),
        params: { comment: comment }
      )
    end

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'reverts a vulnerability and its associated findings to detected state', :aggregate_failures do
        freeze_time do
          revert_vulnerability_to_detected

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/vulnerability', dir: 'ee')

          expect(vulnerability.reload).to(
            have_attributes(state: 'detected', dismissed_by: nil, dismissed_at: nil))
          expect(vulnerability.findings).to all not_have_vulnerability_dismissal_feedback
          expect(vulnerability.state_transitions.last.comment).to eq(comment)
        end
      end

      it_behaves_like 'responds with "not found" for an unknown vulnerability ID'

      context 'when there is a revert error' do
        before do
          Grape::Endpoint.before_each do |endpoint|
            allow(endpoint).to receive(:find_vulnerability!).and_wrap_original do |method, *args|
              vulnerability = method.call(*args)

              errors = ActiveModel::Errors.new(vulnerability)
              errors.add(:base, 'something went wrong')

              allow(vulnerability).to receive(:valid?).and_return(false)
              allow(vulnerability).to receive(:errors).and_return(errors)

              vulnerability
            end
          end
        end

        after do
          # resetting according to the https://github.com/ruby-grape/grape#stubbing-helpers
          Grape::Endpoint.before_each nil
        end

        it 'responds with error', :aggregate_failures do
          revert_vulnerability_to_detected

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('base' => ['something went wrong'])
        end
      end

      context 'if a vulnerability is already in detected state' do
        let(:vulnerability) { create(:vulnerability, :with_findings, :detected, project: project) }

        it 'responds with 304 Not Modified' do
          revert_vulnerability_to_detected

          expect(response).to have_gitlab_http_status(:not_modified)
        end
      end

      it_behaves_like 'forbids access to vulnerability API endpoint in case of disabled features'
    end

    describe 'permissions', :enable_admin_mode do
      it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:admin) }
      it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:owner).of(project) }
      it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:maintainer).of(project) }
      it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:developer).of(project) }

      it { expect { revert_vulnerability_to_detected }.to be_denied_for(:auditor) }
      it { expect { revert_vulnerability_to_detected }.to be_denied_for(:reporter).of(project) }
      it { expect { revert_vulnerability_to_detected }.to be_denied_for(:guest).of(project) }
      it { expect { revert_vulnerability_to_detected }.to be_denied_for(:anonymous) }
    end
  end
end
