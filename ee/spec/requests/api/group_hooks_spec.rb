# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupHooks, :aggregate_failures, feature_category: :integrations do
  let_it_be(:group_admin) { create(:user) }
  let_it_be(:non_admin_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_refind(:hook) do
    create(:group_hook,
      :all_events_enabled,
      group: group,
      url: 'http://example.com',
      enable_ssl_verification: true)
  end

  before do
    group.add_owner(group_admin)
  end

  it_behaves_like 'web-hook API endpoints', '/groups/:id' do
    let(:user) { group_admin }
    let(:unauthorized_user) { non_admin_user }

    def scope
      group.hooks
    end

    def collection_uri
      "/groups/#{group.id}/hooks"
    end

    def match_collection_schema
      match_response_schema('public_api/v4/group_hooks', dir: 'ee')
    end

    def hook_uri(hook_id = hook.id)
      "/groups/#{group.id}/hooks/#{hook_id}"
    end

    def match_hook_schema
      match_response_schema('public_api/v4/group_hook', dir: 'ee')
    end

    def event_names
      %i[
        push_events
        issues_events
        confidential_issues_events
        merge_requests_events
        tag_push_events
        note_events
        confidential_note_events
        job_events
        pipeline_events
        wiki_page_events
        deployment_events
        releases_events
        subgroup_events
      ]
    end

    let(:default_values) do
      { push_events: true, confidential_note_events: nil }
    end

    it_behaves_like 'web-hook API endpoints with branch-filter', '/projects/:id'
  end
end
