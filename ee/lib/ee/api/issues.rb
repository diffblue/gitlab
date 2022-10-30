# frozen_string_literal: true

module EE
  module API
    module Issues
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          namespace ':id/issues/:issue_iid/metric_images' do
            post 'authorize' do
              authorize!(:upload_issuable_metric_image, find_project_issue(request.params[:issue_iid]))

              require_gitlab_workhorse!
              ::Gitlab::Workhorse.verify_api_request!(request.headers)
              status 200
              content_type ::Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

              params = {
                has_length: false,
                maximum_size: ::IssuableMetricImage::MAX_FILE_SIZE.to_i
              }

              ::MetricImageUploader.workhorse_authorize(**params)
            end

            desc 'Upload a metric image for an issue' do
              success Entities::IssuableMetricImage
            end
            params do
              requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The image file to be uploaded', documentation: { type: 'file' }
              optional :url, type: String, desc: 'The url to view more metric info'
              optional :url_text, type: String, desc: 'A description of the image or URL'
            end
            post do
              require_gitlab_workhorse!
              bad_request!('File is too large') if max_file_size_exceeded?

              issue = find_project_issue(params[:issue_iid])

              upload = ::IncidentManagement::Incidents::UploadMetricService.new(
                issue,
                current_user,
                params.slice(:file, :url, :url_text)
              ).execute

              if upload.success?
                present upload.payload[:metric], with: Entities::IssuableMetricImage, current_user: current_user, project: user_project
              else
                render_api_error!(upload.message, 403)
              end
            end

            desc 'Metric Images for issue'
            get do
              issue = find_project_issue(params[:issue_iid])

              if can?(current_user, :read_issuable_metric_image, issue)
                issue = ::IssuesFinder.new(
                  current_user,
                  project_id: user_project.id,
                  iids: [params[:issue_iid]]
                ).execute.first

                present issue.metric_images.order_created_at_asc, with: Entities::IssuableMetricImage
              else
                render_api_error!('Issue not found', 404)
              end
            end

            desc 'Update a metric image for an issue' do
              success Entities::IssuableMetricImage
            end
            params do
              requires :metric_image_id, type: Integer, desc: 'The ID of metric image'
              optional :url, type: String, desc: 'The url to view more metric info'
              optional :url_text, type: String, desc: 'A description of the image or URL'
            end
            put ':metric_image_id' do
              issue = find_project_issue(params[:issue_iid])

              authorize!(:update_issuable_metric_image, issue)

              metric_image = issue.metric_images.find_by_id(params[:metric_image_id])

              render_api_error!('Metric image not found', 404) unless metric_image

              if metric_image&.update(params.slice(:url, :url_text))
                present metric_image, with: Entities::IssuableMetricImage, current_user: current_user, project: user_project
              else
                render_api_error!('Metric image could not be updated', 400)
              end
            end

            desc 'Remove a metric image for an issue' do
              success Entities::IssuableMetricImage
            end
            params do
              requires :metric_image_id, type: Integer, desc: 'The ID of metric image'
            end
            delete ':metric_image_id' do
              issue = find_project_issue(params[:issue_iid])

              authorize!(:destroy_issuable_metric_image, issue)

              metric_image = issue.metric_images.find_by_id(params[:metric_image_id])

              render_api_error!('Metric image not found', 404) unless metric_image

              if metric_image&.destroy
                no_content!
              else
                render_api_error!('Metric image could not be deleted', 400)
              end
            end
          end
        end

        helpers do
          def max_file_size_exceeded?
            params[:file].size > ::IssuableMetricImage::MAX_FILE_SIZE
          end
        end
      end
    end
  end
end
