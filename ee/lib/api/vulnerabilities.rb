# frozen_string_literal: true

module API
  class Vulnerabilities < ::API::Base
    include ::API::Helpers::VulnerabilitiesHooks
    include PaginationParams

    feature_category :vulnerability_management
    urgency :low

    helpers ::API::Helpers::VulnerabilitiesHelpers

    helpers do
      def vulnerabilities_by(project)
        Security::VulnerabilityReadsFinder.new(project).execute.as_vulnerabilities
      end

      def find_vulnerability!
        Vulnerability.with_findings.find(params[:id])
      end

      def render_vulnerability(vulnerability)
        if vulnerability.valid?
          present vulnerability, with: EE::API::Entities::Vulnerability
        else
          render_validation_error!(vulnerability)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a vulnerability'
    end
    resource :vulnerabilities do
      before do
        @vulnerability = find_and_authorize_vulnerability!(:read_security_resource)
      end

      desc 'Get a vulnerability' do
        success EE::API::Entities::Vulnerability
      end
      get ':id' do
        render_vulnerability(@vulnerability)
      end

      desc 'Resolve a vulnerability' do
        success EE::API::Entities::Vulnerability
      end
      params do
        optional :comment,
          type: String,
          desc: 'Comment why vulnerability was reverted to detected (maximum 50,000 characters).'
      end
      post ':id/resolve' do
        not_modified! if @vulnerability.resolved?

        @vulnerability = ::Vulnerabilities::ResolveService.new(current_user, @vulnerability, params[:comment]).execute
        render_vulnerability(@vulnerability)
      end

      desc 'Dismiss a vulnerability' do
        success EE::API::Entities::Vulnerability
      end
      post ':id/dismiss' do
        not_modified! if @vulnerability.dismissed?

        @vulnerability = ::Vulnerabilities::DismissService.new(current_user, @vulnerability).execute
        render_vulnerability(@vulnerability)
      end

      desc 'Confirm a vulnerability' do
        success EE::API::Entities::Vulnerability
      end
      params do
        optional :comment, type: String
      end
      post ':id/confirm' do
        not_modified! if @vulnerability.confirmed?

        @vulnerability = ::Vulnerabilities::ConfirmService.new(current_user, @vulnerability, params[:comment]).execute
        render_vulnerability(@vulnerability)
      end

      desc 'Revert a vulnerability to a detected state' do
        success EE::API::Entities::Vulnerability
      end
      params do
        optional :comment, type: String
      end
      post ':id/revert' do
        not_modified! if @vulnerability.detected?

        @vulnerability = ::Vulnerabilities::RevertToDetectedService.new(current_user, @vulnerability,
          params[:comment]).execute
        render_vulnerability(@vulnerability)
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project vulnerabilities' do
        success EE::API::Entities::Vulnerability
      end
      params do
        use :pagination
      end
      get ':id/vulnerabilities' do
        authorize! :read_security_resource, user_project

        vulnerabilities = paginate(
          vulnerabilities_by(user_project)
        )

        present vulnerabilities, with: EE::API::Entities::Vulnerability
      end

      desc 'Create a new Vulnerability (from a confirmed Finding)' do
        success EE::API::Entities::Vulnerability
      end
      params do
        requires :finding_id, type: Integer, desc: 'The id of confirmed vulnerability finding'
      end
      post ':id/vulnerabilities' do
        authorize! :admin_vulnerability, user_project

        vulnerability = ::Vulnerabilities::CreateService.new(
          user_project, current_user, finding_id: params[:finding_id]
        ).execute

        if vulnerability.persisted?
          present vulnerability, with: EE::API::Entities::Vulnerability
        else
          render_validation_error!(vulnerability)
        end
      end
    end
  end
end
