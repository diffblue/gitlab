# frozen_string_literal: true

module Integrations
  module ZentaoSerializers
    class IssueDetailEntity < IssueEntity
      expose :description_html do |item|
        sanitize(item['desc'])
      end

      expose :comments do |item|
        item['comments'].map do |comment|
          {
            id: comment['id']&.to_i,
            created_at: comment['date']&.to_datetime&.utc,
            body_html: body_html(comment),
            author: user_info(comment['actor'])
          }
        end
      end

      private

      def body_html(comment)
        content = [comment['title'], comment['body_html']].join('<br>')
        sanitize(content)
      end
    end
  end
end
