# frozen_string_literal: true

module API
  class ProjectMirror < ::API::Base
    feature_category :source_code_management

    helpers do
      def github_webhook_signature
        @github_webhook_signature ||= headers['X-Hub-Signature']
      end

      def render_invalid_github_signature!
        if Guest.can?(:read_project, project)
          unauthorized!
        else
          not_found!
        end
      end

      def valid_github_signature?
        request.body.rewind

        token        = project.external_webhook_token.to_s
        payload_body = request.body.read
        signature    = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload_body)

        Rack::Utils.secure_compare(signature, github_webhook_signature)
      end

      def authenticate_with_webhook_token!
        return not_found! unless project

        return if valid_github_signature?

        render_invalid_github_signature!
      end

      def try_authenticate_with_webhook_token!
        if github_webhook_signature
          authenticate_with_webhook_token!
        else
          authenticate!
          authorize_admin_project
        end
      end

      def project
        @project ||= github_webhook_signature ? find_project(params[:id]) : user_project
      end

      def process_pull_request
        external_pull_request = ::Ci::ExternalPullRequests::ProcessGithubEventService.new(project, mirror_user).execute(params)

        if external_pull_request
          render_validation_error!(external_pull_request)
        else
          render_api_error!('The pull request event is not processable', 422)
        end
      end

      def start_pull_mirroring
        result = StartPullMirroringService.new(project, mirror_user, pause_on_hard_failure: true).execute

        render_api_error!(result[:message], result[:http_status]) if result[:status] == :error
      end

      def mirror_user
        current_user || project.mirror_user
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Triggers a pull mirror operation' do
        success code: 200
        failure [
          { code: 400, message: 'The project is not mirrored' },
          { code: 403, message: 'Mirroring for the project is on pause' },
          { code: 422, message: 'The pull request event is not processable' }
        ]
      end
      params do
        optional :action, type: String, desc: 'Pull Request action'
        optional 'pull_request.number', type: Integer, desc: 'Pull request IID'
        optional 'pull_request.head.ref', type: String, desc: 'Source branch'
        optional 'pull_request.head.sha', type: String, desc: 'Source sha'
        optional 'pull_request.head.repo.full_name', type: String, desc: 'Source repository'
        optional 'pull_request.base.ref', type: String, desc: 'Target branch'
        optional 'pull_request.base.sha', type: String, desc: 'Target sha'
        optional 'pull_request.base.repo.full_name', type: String, desc: 'Target repository'
      end
      post ":id/mirror/pull" do
        try_authenticate_with_webhook_token!

        break render_api_error!('The project is not mirrored', 400) unless project.mirror?

        if params[:pull_request]
          process_pull_request
        else
          start_pull_mirroring
        end

        status 200
      end

      desc 'Get a pull mirror' do
        success code: 200, model: Entities::PullMirror
        failure [
          { code: 400, message: 'The project is not mirrored' }
        ]
      end
      get ':id/mirror/pull' do
        authenticate!
        authorize_admin_project

        render_api_error!('The project is not mirrored', 400) unless project.mirror?

        present project.import_state, with: Entities::PullMirror
      end
    end
  end
end
