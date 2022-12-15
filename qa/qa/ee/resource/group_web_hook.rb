# frozen_string_literal: true

module QA
  module EE
    module Resource
      class GroupWebHook < QA::Resource::Base
        EVENT_TRIGGERS = %i[
          push
          issues
          confidential_issues
          merge_requests
          tag_push
          note
          confidential_note
          job
          pipeline
          wiki_page
          deployment
          releases
          subgroup
          member
        ].freeze

        attr_accessor :url, :enable_ssl, :id, :token

        attribute :group do
          QA::Resource::Group.fabricate_via_api! do |resource|
            resource.name = "group-with-webhooks-#{SecureRandom.hex(4)}"
          end
        end

        EVENT_TRIGGERS.each do |trigger|
          attribute "#{trigger}_events".to_sym do
            false
          end
        end

        def initialize
          @id = nil
          @enable_ssl = false
          @url = nil
          @push_events_branch_filter = []
        end

        def add_push_event_branch_filter(branch)
          @push_events_branch_filter << branch
        end

        def resource_web_url(resource)
          "/groups/#{group.id}/-/hooks/##{resource[:id]}/edit"
        end

        def api_get_path
          "/groups/#{group.id}/hooks"
        end

        def api_post_path
          api_get_path
        end

        def api_post_body
          body = {
            id: group.id,
            url: url,
            enable_ssl_verification: enable_ssl,
            token: token,
            push_events_branch_filter: @push_events_branch_filter.join(',')
          }
          EVENT_TRIGGERS.each_with_object(body) do |trigger, memo|
            attr = "#{trigger}_events"
            memo[attr.to_sym] = send(attr)
            memo
          end
        end
      end
    end
  end
end
