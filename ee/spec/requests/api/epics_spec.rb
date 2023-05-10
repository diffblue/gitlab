# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Epics, :aggregate_failures, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }

  let_it_be(:group, reload: true) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:label) { create(:group_label, group: group) }
  let(:label2) { create(:group_label, group: group, title: 'label-2') }
  let!(:epic) { create(:labeled_epic, group: group, labels: [label]) }
  let(:params) { nil }

  shared_examples 'error requests' do
    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        group.add_developer(user)

        get api(url, user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'when epics feature is enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'returns 404 not found error for a user without permissions to see the group' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          get api(url, user), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  shared_examples 'response with extra date fields' do
    let(:extra_date_fields) do
      %w[
        start_date_from_milestones start_date_from_inherited_source start_date_fixed
        start_date_is_fixed due_date_fixed due_date_is_fixed due_date_from_milestones
        due_date_from_inherited_source
      ]
    end

    it 'returns epic with extra date fields' do
      get api(url, user), params: params

      expect(Array.wrap(json_response)).to all(include(*extra_date_fields))
    end
  end

  shared_context 'with labels' do
    before do
      create(:label_link, label: label, target: epic)
      create(:label_link, label: label2, target: epic)
    end
  end

  describe 'GET /groups/:id/epics' do
    let(:url) { "/groups/#{group.path}/epics" }
    let(:params) { { include_descendant_groups: true } }

    it_behaves_like 'error requests'

    context 'when the request is correct' do
      before do
        stub_licensed_features(epics: true)

        get api(url, user), params: params
      end

      it 'returns 200 status' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'matches the response schema' do
        expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
      end

      it 'avoids N+1 queries', :request_store do
        # Avoid polluting queries with inserts for personal access token
        pat = create(:personal_access_token, user: user)
        subgroup_1 = create(:group, parent: group)
        subgroup_2 = create(:group, parent: subgroup_1)
        epic1 = create(:epic, group: subgroup_1)
        epic2 = create(:epic, group: subgroup_2, parent_id: epic.id)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api(url, personal_access_token: pat), params: params
        end.count

        label_2 = create(:label)
        create_list(:labeled_epic, 2, group: group, labels: [label_2])
        create_list(:epic, 2, group: subgroup_1, parent_id: epic1.id)
        create_list(:epic, 2, group: subgroup_2, parent_id: epic2.id)

        expect { get api(url, personal_access_token: pat), params: params }.not_to exceed_all_query_limit(control)
        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'with_label_details' do
        let(:params) do
          {
            include_descendant_groups: true,
            with_labels_details: true
          }
        end

        it 'avoids N+1 queries', :request_store do
          # Avoid polluting queries with inserts for personal access token
          pat = create(:personal_access_token, user: user)
          subgroup_1 = create(:group, parent: group)
          subgroup_2 = create(:group, parent: subgroup_1)
          label_1 = create(:group_label, title: 'foo', group: group)
          epic1 = create(:epic, group: subgroup_2)
          create(:label_link, label: label_1, target: epic1)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api(url, personal_access_token: pat), params: params
          end.count

          label_2 = create(:label)
          create_list(:labeled_epic, 4, group: group, labels: [label_2])

          expect do
            get api(url, personal_access_token: pat), params: params
          end.not_to exceed_all_query_limit(control)
        end

        it 'returns labels with details' do
          label_1 = create(:group_label, title: 'foo', group: group)
          label_2 = create(:label, title: 'bar', project: project)

          create(:label_link, label: label_1, target: epic)
          create(:label_link, label: label_2, target: epic)

          get api(url), params: { labels: [label.title, label_1.title, label_2.title], with_labels_details: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect_paginated_array_response([epic.id])
          expect(json_response.first['labels'].pluck('name')).to match_array([label.title, label_1.title, label_2.title])
          expect(json_response.last['labels'].first).to match_schema('/public_api/v4/label_basic')
        end
      end
    end

    context 'with a parent epic' do
      let_it_be(:epic) { create(:epic, group: group) }
      let_it_be(:epic2) { create(:epic, group: group, parent_id: epic.id) }

      before do
        stub_licensed_features(epics: true)
      end

      it 'returns parent_id and parent_iid' do
        get api(url, user)

        epics = json_response

        expect(epics.map { |e| e["parent_id"] }).to match_array([nil, epic.id])
        expect(epics.map { |e| e["parent_iid"] }).to match_array([nil, epic.iid])
      end
    end

    context 'with multiple epics' do
      let(:user2) { create(:user) }
      let!(:epic) do
        create(:epic,
               group: group,
               title: 'baz',
               state: :closed,
               created_at: 3.days.ago,
               updated_at: 2.days.ago)
      end

      let!(:epic2) do
        create(:epic,
               author: user2,
               group: group,
               title: 'foo',
               description: 'bar',
               created_at: 2.days.ago,
               updated_at: 3.days.ago)
      end

      let!(:label) { create(:group_label, title: 'a-test', group: group) }
      let!(:label_link) { create(:label_link, label: label, target: epic2) }

      before do
        stub_licensed_features(epics: true)
      end

      it 'returns epics not authored by the given author id' do
        get api(url), params: { not: { author_id: user2.id } }

        expect_paginated_array_response([epic.id])
      end

      it 'returns epics not authored by the given author username' do
        get api(url), params: { not: { author_username: user2.username } }

        expect_paginated_array_response([epic.id])
      end

      it 'does not allow filtering by negating author_id and author_username together' do
        get api(url), params: { not: { author_id: user2.id, author_username: user2.username } }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns epics without the given label' do
        get api(url), params: { not: { labels: label.title } }

        expect_paginated_array_response([epic.id])
      end

      it 'returns epics authored by the given author id' do
        get api(url), params: { author_id: user2.id }

        expect_paginated_array_response([epic2.id])
      end

      it 'returns epics authored by the given author username' do
        get api(url), params: { author_username: user2.username }

        expect_paginated_array_response([epic2.id])
      end

      it 'does not allow filtering by author_id and author_username together' do
        get api(url), params: { author_id: user2.id, author_username: user2.username }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns epics reacted to by current user' do
        create(:award_emoji, awardable: epic, user: user, name: 'star')
        create(:award_emoji, awardable: epic2, user: user2, name: 'star')

        get api(url, user), params: { my_reaction_emoji: 'Any', scope: 'all' }

        expect_paginated_array_response([epic.id])
      end

      it 'returns epics matching given status' do
        get api(url, user), params: { state: :opened }

        expect_paginated_array_response([epic2.id])
      end

      it 'returns all epics when state set to all' do
        get api(url), params: { state: :all }

        expect_paginated_array_response([epic2.id, epic.id])
      end

      it 'returns epics matching given confidentiality' do
        group.add_developer(user)

        epic3 = create(:epic, group: group, confidential: true)

        get api(url, user), params: { confidential: true }

        expect_paginated_array_response([epic3.id])
      end

      it 'has upvote/downvote information' do
        create(:award_emoji, name: 'thumbsup', awardable: epic, user: user )
        create(:award_emoji, name: 'thumbsdown', awardable: epic2, user: user )

        get api(url)

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response).to contain_exactly(
          a_hash_including('upvotes' => 1, 'downvotes' => 0),
          a_hash_including('upvotes' => 0, 'downvotes' => 1)
        )
      end

      it 'sorts by created_at descending by default' do
        get api(url)

        expect_paginated_array_response([epic2.id, epic.id])
      end

      it 'sorts ascending when requested' do
        get api(url), params: { sort: :asc }

        expect_paginated_array_response([epic.id, epic2.id])
      end

      it 'sorts by updated_at descending when requested' do
        get api(url), params: { order_by: :updated_at }

        expect_paginated_array_response([epic.id, epic2.id])
      end

      it 'sorts by updated_at ascending when requested' do
        get api(url), params: { order_by: :updated_at, sort: :asc }

        expect_paginated_array_response([epic2.id, epic.id])
      end

      it 'sorts by title descending when requested' do
        get api(url), params: { order_by: :title }

        expect_paginated_array_response([epic2.id, epic.id])
      end

      it 'sorts by title ascending when requested' do
        get api(url), params: { order_by: :title, sort: :asc }

        expect_paginated_array_response([epic.id, epic2.id])
      end

      it 'returns an array of labeled epics' do
        get api(url), params: { labels: label.title }

        expect_paginated_array_response([epic2.id])
      end

      it 'returns an array of labeled epics with labels param as array' do
        get api(url), params: { labels: [label.title] }

        expect_paginated_array_response([epic2.id])
      end

      it 'returns an array of labeled epics when all labels matches' do
        label_b = create(:group_label, title: 'foo', group: group)
        label_c = create(:label, title: 'bar', project: project)

        create(:label_link, label: label_b, target: epic2)
        create(:label_link, label: label_c, target: epic2)

        get api(url), params: { labels: "#{label.title},#{label_b.title},#{label_c.title}" }

        expect_paginated_array_response([epic2.id])
        expect(json_response.first['labels']).to match_array([label.title, label_b.title, label_c.title])
      end

      it 'returns an array of labeled epics when all labels matches with labels param as array' do
        label_b = create(:group_label, title: 'foo', group: group)
        label_c = create(:label, title: 'bar', project: project)

        create(:label_link, label: label_b, target: epic2)
        create(:label_link, label: label_c, target: epic2)

        get api(url), params: { labels: [label.title, label_b.title, label_c.title] }

        expect_paginated_array_response([epic2.id])
        expect(json_response.first['labels']).to match_array([label.title, label_b.title, label_c.title])
      end

      it 'returns an empty array if no epic matches labels' do
        get api(url), params: { labels: 'foo,bar' }

        expect_paginated_array_response([])
      end

      it 'returns an empty array if no epic matches labels with labels param as array' do
        get api(url), params: { labels: %w(foo bar) }

        expect_paginated_array_response([])
      end

      it 'returns an array of labeled epics matching given state' do
        get api(url), params: { labels: label.title, state: :opened }

        expect_paginated_array_response(epic2.id)
        expect(json_response.first['labels']).to eq([label.title])
        expect(json_response.first['state']).to eq('opened')
      end

      it 'returns an array of labeled epics matching given state with labels param as array' do
        get api(url), params: { labels: [label.title], state: :opened }

        expect_paginated_array_response(epic2.id)
        expect(json_response.first['labels']).to eq([label.title])
        expect(json_response.first['state']).to eq('opened')
      end

      it 'returns an empty array if no epic matches labels and state filters' do
        get api(url), params: { labels: label.title, state: :closed }

        expect_paginated_array_response([])
      end

      it 'returns an array of epics with any label' do
        get api(url), params: { labels: IssuableFinder::Params::FILTER_ANY }

        expect_paginated_array_response(epic2.id)
      end

      it 'returns an array of epics with any label with labels param as array' do
        get api(url), params: { labels: [IssuableFinder::Params::FILTER_ANY] }

        expect_paginated_array_response(epic2.id)
      end

      it 'returns an array of epics with no label' do
        get api(url), params: { labels: IssuableFinder::Params::FILTER_NONE }

        expect_paginated_array_response(epic.id)
      end

      it 'returns an array of epics with no label with labels param as array' do
        get api(url), params: { labels: [IssuableFinder::Params::FILTER_NONE] }

        expect_paginated_array_response(epic.id)
      end

      context 'with search param' do
        it 'returns issues matching given search string for title' do
          get api(url, user), params: { search: epic2.title }

          expect_paginated_array_response(epic2.id)
        end

        it 'returns issues matching given search string for description' do
          get api(url, user), params: { search: epic2.description }

          expect_paginated_array_response(epic2.id)
        end

        it_behaves_like 'issuable API rate-limited search' do
          let(:issuable) { epic2 }
        end
      end

      describe "#to_reference" do
        it 'exposes reference path' do
          get api(url)

          expect(json_response.first['references']['short']).to eq("&#{epic2.iid}")
          expect(json_response.first['references']['relative']).to eq("&#{epic2.iid}")
          expect(json_response.first['references']['full']).to eq("#{epic2.group.path}&#{epic2.iid}")
        end

        context 'referencing from parent group' do
          let(:parent_group) { create(:group) }

          before do
            group.update!(parent_id: parent_group.id)
          end

          it 'exposes full reference path' do
            get api("/groups/#{parent_group.path}/epics")

            expect(json_response.first['references']['short']).to eq("&#{epic2.iid}")
            expect(json_response.first['references']['relative']).to eq("#{parent_group.path}/#{epic2.group.path}&#{epic2.iid}")
            expect(json_response.first['references']['full']).to eq("#{parent_group.path}/#{epic2.group.path}&#{epic2.iid}")
          end
        end
      end

      it_behaves_like 'response with extra date fields'
    end

    context 'filtering before a specific date' do
      let!(:epic) { create(:epic, group: group, created_at: Date.new(2000, 1, 1), updated_at: Date.new(2000, 1, 1)) }

      before do
        stub_licensed_features(epics: true)
      end

      it 'returns epics created before a specific date' do
        get api(url), params: { created_before: '2000-01-02T00:00:00.060Z' }

        expect_paginated_array_response(epic.id)
      end

      it 'returns epics updated before a specific date' do
        get api(url), params: { updated_before: '2000-01-02T00:00:00.060Z' }

        expect_paginated_array_response(epic.id)
      end
    end

    context 'filtering after a specific date' do
      let!(:epic) { create(:epic, group: group, created_at: 1.week.from_now, updated_at: 1.week.from_now) }

      before do
        stub_licensed_features(epics: true)
      end

      it 'returns epics created after a specific date' do
        get api(url), params: { created_after: epic.created_at }

        expect_paginated_array_response(epic.id)
      end

      it 'returns epics updated after a specific date' do
        get api(url), params: { updated_after: epic.updated_at }

        expect_paginated_array_response(epic.id)
      end
    end

    context 'with hierarchy params' do
      let(:subgroup) { create(:group, parent: group) }
      let(:subgroup2) { create(:group, parent: subgroup) }
      let!(:subgroup_epic) { create(:epic, group: subgroup) }
      let!(:subgroup2_epic) { create(:epic, group: subgroup2) }

      let(:url) { "/groups/#{subgroup.id}/epics" }

      before do
        stub_licensed_features(epics: true)
      end

      it 'excludes descendant group epics' do
        get api(url), params: { include_descendant_groups: false }

        expect_paginated_array_response(subgroup_epic.id)
      end

      it 'includes ancestor group epics' do
        get api(url), params: { include_ancestor_groups: true }

        expect_paginated_array_response([subgroup2_epic.id, subgroup_epic.id, epic.id])
      end
    end

    context 'with pagination params' do
      let(:page) { 1 }
      let(:per_page) { 2 }
      let!(:epic1) { create(:epic, group: group, created_at: 3.days.ago) }
      let!(:epic2) { create(:epic, group: group, created_at: 2.days.ago) }
      let!(:epic3) { create(:epic, group: group, created_at: 1.day.ago) }

      before do
        stub_licensed_features(epics: true)
      end

      shared_examples 'paginated API endpoint' do
        it 'returns the correct page' do
          get api(url), params: { page: page, per_page: per_page }

          expect(response.headers['X-Page']).to eq(page.to_s)
          expect_paginated_array_response(expected)
        end
      end

      context 'when viewing the first page' do
        let(:expected) { [epic.id, epic3.id] }
        let(:page) { 1 }

        it_behaves_like 'paginated API endpoint'
      end

      context 'viewing the second page' do
        let(:expected) { [epic2.id, epic1.id] }
        let(:page) { 2 }

        it_behaves_like 'paginated API endpoint'
      end
    end
  end

  describe 'GET /groups/:id/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}" }

    it_behaves_like 'error requests'

    context 'when the request is correct' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'returns 200 status' do
        get api(url)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'matches the response schema' do
        get api(url)

        expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
      end

      it 'exposes subscribed field' do
        get api(url, epic.author)

        expect(json_response['subscribed']).to eq(true)
      end

      it 'exposes closed_at attribute' do
        epic.close

        get api(url)

        expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
        expect(json_response['closed_at']).to be_present
      end

      it 'exposes full reference path' do
        get api(url)

        expect(json_response['references']['short']).to eq("&#{epic.iid}")
        expect(json_response['references']['relative']).to eq("&#{epic.iid}")
        expect(json_response['references']['full']).to eq("#{epic.group.path}&#{epic.iid}")
      end

      it 'exposes links' do
        get api(url)

        links = json_response['_links']

        expect(links['self']).to end_with("/api/v4/groups/#{epic.group.id}/epics/#{epic.iid}")
        expect(links['epic_issues']).to end_with("/api/v4/groups/#{epic.group.id}/epics/#{epic.iid}/issues")
        expect(links['group']).to end_with("/api/v4/groups/#{epic.group.id}")
        expect(links['parent']).to eq(nil)
      end

      context 'with a parent epic' do
        let!(:epic2) { create(:epic, group: group, parent_id: epic.id) }
        let(:url) { "/groups/#{group.path}/epics/#{epic2.iid}" }

        it 'exposes parent link' do
          get api(url)

          links = json_response['_links']

          expect(links['parent']).to end_with("/api/v4/groups/#{epic.group.id}/epics/#{epic.iid}")
        end
      end

      it_behaves_like 'response with extra date fields'
    end
  end

  describe 'POST /groups/:id/epics' do
    let(:url) { "/groups/#{group.path}/epics" }
    let_it_be(:parent_epic) { create(:epic, group: group) }
    let(:params) do
      {
        title: 'new epic',
        description: 'epic description',
        labels: 'label1',
        due_date_fixed: '2018-07-17',
        due_date_is_fixed: true,
        parent_id: parent_epic.id,
        confidential: true
      }
    end

    it_behaves_like 'error requests'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
        group.add_developer(user)
      end

      it_behaves_like 'POST request permissions for admin mode' do
        let(:path) { url }
      end

      context 'when required parameter is missing' do
        it 'returns 400' do
          post api(url, user), params: { description: 'epic description' }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the request is correct' do
        before do
          post api(url, user), params: params
        end

        it 'returns 201 status' do
          expect(response).to have_gitlab_http_status(:created)
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
        end

        it 'exposes parent information' do
          post api(url, user), params: params

          expect(json_response['parent_id']).to eq(parent_epic.id)
          expect(json_response['parent_iid']).to eq(parent_epic.iid)
          expect(json_response['_links']['parent']).to end_with("/api/v4/groups/#{parent_epic.group.id}/epics/#{parent_epic.iid}")
        end

        it 'create system notes for new relation' do
          post api(url, user), params: params

          new_epic = Epic.last

          expect(parent_epic.notes.last&.note).to eq("added epic #{new_epic.to_reference} as child epic")
          expect(new_epic.notes.last&.note).to eq("added epic #{parent_epic.to_reference} as parent epic")
        end

        it 'creates a new epic' do
          epic = Epic.last

          expect(epic.title).to eq('new epic')
          expect(epic.description).to eq('epic description')
          expect(epic.start_date_fixed).to eq(nil)
          expect(epic.start_date_is_fixed).to be_falsey
          expect(epic.due_date).to eq(Date.new(2018, 7, 17))
          expect(epic.due_date_fixed).to eq(Date.new(2018, 7, 17))
          expect(epic.due_date_is_fixed).to eq(true)
          expect(epic.labels.first.title).to eq('label1')
          expect(epic.parent).to eq(parent_epic)
          expect(epic.relative_position).not_to be_nil
          expect(epic.confidential).to be_truthy
          expect(epic.color).to be_color(::EE::Epic::DEFAULT_COLOR)
          expect(epic.text_color).to be_color(::EE::Epic::DEFAULT_COLOR.contrast)
        end

        context 'when we specify a color by hex code' do
          let(:params) do
            {
              title: 'new epic',
              description: 'epic description',
              labels: 'label1',
              due_date_fixed: '2018-07-17',
              due_date_is_fixed: true,
              parent_id: parent_epic.id,
              confidential: true,
              color: '#fefefe'
            }
          end

          it 'sets the color correctly' do
            epic = Epic.last

            expect(epic.color).to be_color(::Gitlab::Color.of(params[:color]))
            expect(epic.text_color).to be_color(::Gitlab::Color.of(params[:color]).contrast)
          end
        end

        context 'when we specify a color by name' do
          let(:params) do
            {
              title: 'new epic',
              description: 'epic description',
              labels: 'label1',
              due_date_fixed: '2018-07-17',
              due_date_is_fixed: true,
              parent_id: parent_epic.id,
              confidential: true,
              color: 'red'
            }
          end

          it 'sets the color correctly' do
            epic = Epic.last

            expect(epic.color).to be_color(::Gitlab::Color.of(params[:color]))
            expect(epic.text_color).to be_color(::Gitlab::Color.of(params[:color]).contrast)
          end
        end

        context 'when deprecated start_date and end_date params are present' do
          let(:start_date) { Date.new(2001, 1, 1) }
          let(:due_date) { Date.new(2001, 1, 2) }
          let(:params) { { title: 'new epic', start_date: start_date, end_date: due_date } }

          it 'updates start_date_fixed and due_date_fixed' do
            result = Epic.last

            expect(result.start_date_fixed).to eq(start_date)
            expect(result.due_date_fixed).to eq(due_date)
          end
        end

        context 'when parent epic is invalid' do
          let_it_be(:confidential_parent) { create(:epic, group: group, confidential: true) }

          let(:params) do
            {
              title: 'new epic',
              description: 'epic description',
              parent_id: confidential_parent.id,
              confidential: false
            }
          end

          it 'returns 400' do
            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']['confidential'])
              .to include('A non-confidential epic cannot be assigned to a confidential parent epic')
          end

          context 'when user has no access to parent epic' do
            let_it_be(:external_epic) { create(:epic, group: create(:group, :private)) }

            let(:params) { { title: 'new epic', parent_id: external_epic.id } }

            it 'creates epic without parent' do
              expect(response).to have_gitlab_http_status(:success)
              new_epic = Epic.last

              expect(new_epic.parent).to be_nil
            end
          end
        end
      end

      context 'with rate limiter', :freeze_time, :clean_gitlab_redis_rate_limiting do
        before do
          stub_application_setting(issues_create_limit: 1)
        end

        it 'prevents users from creating more epics' do
          post api(url, user), params: params

          expect(response).to have_gitlab_http_status(:created)

          post api(url, user), params: params

          expect(response).to have_gitlab_http_status(:too_many_requests)
          expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
        end
      end

      context 'setting created_at' do
        let(:creation_time) { 2.weeks.ago }
        let(:params) { { title: 'new epic', created_at: creation_time } }

        it 'sets the creation time on the new epic if the user is an admin' do
          admin = create(:user, :admin)

          post api(url, admin, admin_mode: true), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
        end

        it 'sets the creation time on the new epic if the user is a group owner' do
          group.add_owner(user)

          post api(url, user), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
        end

        it 'ignores the given creation time if the user is another user' do
          user2 = create(:user)
          group.add_developer(user2)

          post api(url, user2), params: params

          expect(response).to have_gitlab_http_status(:created)
          expect(Time.parse(json_response['created_at'])).not_to be_like_time(creation_time)
        end
      end

      it 'creates a new epic with labels param as array' do
        params[:labels] = ['label1', 'label2', 'foo, bar', '&,?']

        post api(url, user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to include 'new epic'
        expect(json_response['description']).to include 'epic description'
        expect(json_response['labels']).to include 'label1'
        expect(json_response['labels']).to include 'label2'
        expect(json_response['labels']).to include 'foo'
        expect(json_response['labels']).to include 'bar'
        expect(json_response['labels']).to include '&'
        expect(json_response['labels']).to include '?'
      end

      it 'creates a new epic with no labels' do
        params[:labels] = nil

        post api(url, user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to include 'new epic'
        expect(json_response['description']).to include 'epic description'
        expect(json_response['labels']).to be_empty
      end
    end
  end

  describe 'PUT /groups/:id/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}" }
    let!(:epic2) { create(:epic, group: group) }
    let(:params) do
      {
        title: 'new title',
        description: 'new description',
        labels: 'label2',
        start_date_fixed: "2018-07-17",
        start_date_is_fixed: true,
        confidential: true,
        parent_id: epic2.id
      }
    end

    it_behaves_like 'error requests'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      it_behaves_like 'PUT request permissions for admin mode' do
        let(:path) { url }
      end

      context 'when a user does not have permissions to create an epic' do
        it 'returns 403 forbidden error' do
          put api(url, user), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when no param sent' do
        it 'returns 400' do
          group.add_developer(user)

          put api(url, user)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when user has no access to parent epic' do
        let!(:epic2) { create(:epic, group: create(:group, :private)) }

        it 'does not update parent' do
          group.add_developer(user)

          put api(url, user), params: params

          expect(response).to have_gitlab_http_status(:success)

          expect(epic.reload.parent).to be_nil
        end
      end

      context 'when the request is correct' do
        before do
          group.add_developer(user)
        end

        context 'with basic params' do
          before do
            put api(url, user), params: params
          end

          it 'returns 200 status' do
            expect(response).to have_gitlab_http_status(:ok)
          end

          it 'matches the response schema' do
            expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
          end

          it 'updates the epic' do
            result = epic.reload

            expect(result.title).to eq('new title')
            expect(result.description).to eq('new description')
            expect(result.labels.first.title).to eq('label2')
            expect(result.start_date).to eq(Date.new(2018, 7, 17))
            expect(result.start_date_fixed).to eq(Date.new(2018, 7, 17))
            expect(result.start_date_is_fixed).to eq(true)
            expect(result.due_date_fixed).to eq(nil)
            expect(result.due_date_is_fixed).to be_falsey
            expect(result.confidential).to be_truthy
            expect(result.parent_id).to eq(epic2.id)
          end
        end

        it 'clears labels when labels param is nil' do
          params[:labels] = 'label1'
          put api(url, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['title']).to include 'new title'
          expect(json_response['description']).to include 'new description'
          expect(json_response['labels']).to contain_exactly('label1')

          params[:labels] = nil
          put api(url, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          json_response = Gitlab::Json.parse(response.body)
          expect(json_response['title']).to include 'new title'
          expect(json_response['description']).to include 'new description'
          expect(json_response['labels']).to be_empty
        end

        context 'with labels' do
          include_context 'with labels'

          it 'updates the epic with labels param as array' do
            allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(110)

            params[:labels] = ['label1', 'label2', 'foo, bar', '&,?']

            put api(url, user), params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['title']).to include 'new title'
            expect(json_response['description']).to include 'new description'
            expect(json_response['labels']).to include 'label1'
            expect(json_response['labels']).to include 'label2'
            expect(json_response['labels']).to include 'foo'
            expect(json_response['labels']).to include 'bar'
            expect(json_response['labels']).to include '&'
            expect(json_response['labels']).to include '?'
          end

          it 'when adding labels, keeps existing labels and adds new' do
            put api(url, user), params: { add_labels: '1, 2' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['labels']).to contain_exactly(label.title, label2.title, '1', '2')
          end

          it 'when removing labels, only removes those specified' do
            put api(url, user), params: { remove_labels: label.title }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['labels']).to eq([label2.title])
          end

          it 'when removing all labels, keeps no labels' do
            put api(url, user), params: { remove_labels: "#{label.title}, #{label2.title}" }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['labels']).to be_empty
          end
        end

        context 'when state_event is close' do
          it 'allows epic to be closed' do
            put api(url, user), params: { state_event: 'close' }

            expect(epic.reload).to be_closed
          end
        end

        context 'when state_event is reopen' do
          it 'allows epic to be reopend' do
            epic.update!(state: 'closed')

            put api(url, user), params: { state_event: 'reopen' }

            expect(epic.reload).to be_opened
          end
        end

        context 'setting updated_at' do
          let(:update_time) { 1.week.ago }

          it 'ignores the given update time when run by another user' do
            user2 = create(:user)
            group.add_developer(user2)

            put api(url, user2), params: { title: 'updated by other user', updated_at: update_time }

            expect(response).to have_gitlab_http_status(:ok)
            expect(Time.parse(json_response['updated_at'])).not_to be_like_time(update_time)
          end

          it 'sets the update time on the epic when run by an admin' do
            admin = create(:user, :admin)

            put api(url, admin, admin_mode: true), params: { title: 'updated by admin', updated_at: update_time }

            expect(response).to have_gitlab_http_status(:ok)
            expect(Time.parse(json_response['updated_at'])).to be_like_time(update_time)
          end

          it 'sets the update time on the epic when run by a group owner' do
            group.add_owner(user)

            put api(url, user), params: { title: 'updated by owner', updated_at: update_time }

            expect(response).to have_gitlab_http_status(:ok)
            expect(Time.parse(json_response['updated_at'])).to be_like_time(update_time)
          end
        end

        context 'when deprecated start_date and end_date params are present' do
          let(:epic) { create(:epic, :use_fixed_dates, group: group) }
          let(:new_start_date) { epic.start_date + 1.day }
          let(:new_due_date) { epic.end_date + 1.day }

          it 'updates start_date_fixed and due_date_fixed' do
            put api(url, user), params: { start_date: new_start_date, end_date: new_due_date }

            result = epic.reload

            expect(result.start_date_fixed).to eq(new_start_date)
            expect(result.due_date_fixed).to eq(new_due_date)
          end
        end

        context 'when updating start_date_is_fixed by itself' do
          let(:epic) { create(:epic, :use_fixed_dates, group: group) }
          let(:new_start_date) { epic.start_date + 1.day }
          let(:new_due_date) { epic.end_date + 1.day }

          it 'updates start_date_is_fixed' do
            put api(url, user), params: { start_date_is_fixed: false }

            result = epic.reload

            expect(result.start_date_is_fixed).to eq(false)
          end
        end
      end
    end
  end

  describe 'DELETE /groups/:id/epics/:epic_iid' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}" }

    it_behaves_like 'error requests'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user does not have permissions to destroy an epic' do
        it 'returns 403 forbidden error' do
          group.add_developer(user)

          delete api(url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when the request is correct' do
        before do
          group.add_owner(user)
        end

        it 'returns 204 status' do
          delete api(url, user)

          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'removes an epic' do
          epic

          expect { delete api(url, user) }.to change { Epic.count }.from(1).to(0)
        end
      end
    end
  end
end
