# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Secure
          class AuditEvents < QA::Page::Base
            view 'ee/app/assets/javascripts/audit_events/components/audit_events_app.vue' do
              element 'audit-events-tabs'
              element 'streams-tab'
              element 'streams-tab-button'
            end

            view 'ee/app/assets/javascripts/audit_events/components/audit_events_stream.vue' do
              element 'stream-destinations'
            end

            view 'ee/app/assets/javascripts/audit_events/components/stream/stream_destination_editor.vue' do
              element 'destination-name'
              element 'destination-url'
              element 'stream-destination-add-button'
            end

            view 'ee/app/assets/javascripts/audit_events/components/stream/stream_empty_state.vue' do
              element 'dropdown-toggle'
              element 'add-http-destination'
            end

            view 'ee/app/assets/javascripts/audit_events/components/stream/stream_item.vue' do
              element 'toggle-btn'
            end

            def add_streaming_destination(name, url)
              click_element('dropdown-toggle')
              click_element('add-http-destination')
              fill_element('destination-name', name)
              fill_element('destination-url', url)
              click_element('stream-destination-add-button')
            end

            def click_streams_tab
              click_element('streams-tab-button')
              find_element('streams-tab')
              wait_for_requests
            end

            def has_stream_destination?(name)
              within_element('stream-destinations') do
                has_element?('toggle-btn', text: name)
              end
            end
          end
        end
      end
    end
  end
end
