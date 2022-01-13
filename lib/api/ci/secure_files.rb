# frozen_string_literal: true

module API
  module Ci
    class SecureFiles < ::API::Base
      include PaginationParams

      before do
        authenticate!
        authorize! :admin_build, user_project
      end

      feature_category :pipeline_authoring

      default_format :json

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end

      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'List all Secure Files for a Project'
        params do
          use :pagination
        end
        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        get ':id/secure_files' do
          secure_files = user_project.secure_files
          present paginate(secure_files), with: Entities::Ci::SecureFile
        end

        desc 'Get an individual Secure File'
        params do
          requires :id, type: Integer, desc: 'The Secure File ID'
        end

        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        get ':id/secure_files/:secure_file_id' do
          secure_file = user_project.secure_files.find(params[:secure_file_id])
          not_found!('Secure File') unless secure_file
          present secure_file, with: Entities::Ci::SecureFile
        end

        desc 'Download a Secure File'
        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        get ':id/secure_files/:secure_file_id/download' do
          secure_file = user_project.secure_files.find(params[:secure_file_id])
          not_found!('Secure File') unless secure_file

          content_type 'application/octet-stream'
          env['api.format'] = :binary
          header['Content-Disposition'] = "attachment; filename=#{secure_file.name}"
          body secure_file.file.read
        end

        desc 'Upload a Secure File'
        params do
          requires :name, type: String, desc: 'The name of the file'
          requires :file, types: [Rack::Multipart::UploadedFile, ::API::Validations::Types::WorkhorseFile], desc: 'The secure file file to be uploaded'
          optional :permissions, type: String, desc: 'The file permissions'
        end

        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        post ':id/secure_files' do
          secure_file = user_project.secure_files.new(
            name: params[:name],
            permissions: params[:permissions] || :read_only
          )

          secure_file.file = params[:file]

          if secure_file.valid?
            secure_file.save!
            present secure_file, with: Entities::Ci::SecureFile
          else
            render_validation_error!(secure_file)
          end
        end

        desc 'Delete an individual Secure File'
        route_setting :authentication, basic_auth_personal_access_token: true, job_token_allowed: true
        delete ':id/secure_files/:secure_file_id' do
          secure_file = user_project.secure_files.find(params[:secure_file_id])

          not_found!('Secure File') unless secure_file

          secure_file.destroy!

          no_content!
        end
      end
    end
  end
end
