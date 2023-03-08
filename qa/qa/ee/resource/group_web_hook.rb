# frozen_string_literal: true

module QA
  module EE
    module Resource
      class GroupWebHook < QA::Resource::WebHookBase
        extend QA::Resource::Integrations::WebHook::Smockerable

        attributes :alert_status, :disabled_until

        attribute :group do
          QA::Resource::Group.fabricate_via_api! do |resource|
            resource.name = "group-with-webhooks-#{SecureRandom.hex(4)}"
          end
        end

        EVENT_TRIGGERS = QA::Resource::ProjectWebHook::EVENT_TRIGGERS + %i[subgroup]

        EVENT_TRIGGERS.each do |trigger|
          attribute "#{trigger}_events".to_sym do
            false
          end
        end

        def initialize
          super

          @push_events_branch_filter = []
        end

        def add_push_event_branch_filter(branch)
          @push_events_branch_filter << branch
        end

        def resource_web_url(resource)
          "/groups/#{group.id}/-/hooks/##{resource[:id]}/edit"
        end

        def api_get_path
          "#{api_post_path}/#{id}"
        end

        def api_post_path
          "/groups/#{group.id}/hooks"
        end

        def api_post_body
          body = {
            id: group.id,
            url: url,
            enable_ssl_verification: enable_ssl_verification,
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
