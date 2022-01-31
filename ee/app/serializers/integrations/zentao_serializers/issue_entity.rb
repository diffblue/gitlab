# frozen_string_literal: true

module Integrations
  module ZentaoSerializers
    class IssueEntity < Grape::Entity
      include ActionView::Helpers::SanitizeHelper
      include RequestAwareEntity

      expose :id do |item|
        sanitize(item['id'])
      end

      expose :project_id do |item|
        project.id
      end

      expose :title do |item|
        sanitize(item['title'])
      end

      expose :created_at do |item|
        item['openedDate']&.to_datetime&.utc
      end

      expose :updated_at do |item|
        item['lastEditedDate']&.to_datetime&.utc
      end

      expose :closed_at do |item|
        item['lastEditedDate']&.to_datetime&.utc if item['status'] == 'closed'
      end

      expose :status do |item|
        sanitize(item['status'])
      end

      expose :state do |item|
        sanitize(item['status'])
      end

      expose :labels do |item|
        item['labels'].compact.map do |label|
          name = sanitize(label)
          {
            id: name,
            title: name,
            name: name,
            color: '#0052CC',
            text_color: '#FFFFFF'
          }
        end
      end

      expose :author do |item|
        user_info(item['openedBy'])
      end

      expose :assignees do |item|
        item['assignedTo'].compact.map do |user|
          user_info(user)
        end
      end

      expose :web_url do |item|
        item['url']
      end

      expose :gitlab_web_url do |item|
        project_integrations_zentao_issue_path(project, item['id'])
      end

      private

      def project
        @project ||= options[:project]
      end

      def user_info(user)
        return {} unless user.present?

        {
          "id": user['id'],
          "name": sanitize(user['realname'].presence || user['account']),
          "web_url": user['url'],
          "avatar_url": user['avatar']
        }
      end
    end
  end
end
