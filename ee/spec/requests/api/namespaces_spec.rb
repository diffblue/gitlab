# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Namespaces, :aggregate_failures, feature_category: :subgroups do
  include AfterNextHelpers

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  let_it_be(:group1, reload: true) { create(:group, name: 'test.test-group.2') }
  let_it_be(:group2) { create(:group, :nested) }
  let_it_be(:ultimate_plan) { create(:ultimate_plan) }
  let_it_be(:project) { create(:project, namespace: group2) }
  let_it_be(:project) { create(:project, namespace: group2, name: group2.name, path: group2.path) }
  let_it_be(:project_namespace) { project.project_namespace }

  describe "GET /namespaces" do
    context "when authenticated as admin" do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it "returns correct attributes" do
        get api("/namespaces", admin, admin_mode: true)

        group_kind_json_response = json_response.find { |resource| resource['kind'] == 'group' }
        user_kind_json_response = json_response.find { |resource| resource['kind'] == 'user' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(group_kind_json_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path',
                                                                 'parent_id', 'members_count_with_descendants',
                                                                 'plan', 'shared_runners_minutes_limit',
                                                                 'avatar_url', 'web_url', 'trial_ends_on', 'trial',
                                                                 'extra_shared_runners_minutes_limit', 'billable_members_count',
                                                                 'additional_purchased_storage_size', 'additional_purchased_storage_ends_on')

        expect(user_kind_json_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path',
                                                                'parent_id', 'plan', 'shared_runners_minutes_limit',
                                                                'avatar_url', 'web_url', 'trial_ends_on', 'trial',
                                                                'extra_shared_runners_minutes_limit', 'billable_members_count',
                                                                'additional_purchased_storage_size', 'additional_purchased_storage_ends_on')
      end
    end

    context "when authenticated as a regular user" do
      it "returns correct attributes when user can admin group" do
        group1.add_owner(user)

        get api("/namespaces", user)

        owned_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(owned_group_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path', 'trial_ends_on',
                                                             'plan', 'parent_id', 'members_count_with_descendants', 'trial',
                                                             'avatar_url', 'web_url', 'billable_members_count')
      end

      it "returns correct attributes when user cannot admin group" do
        group1.add_guest(user)

        get api("/namespaces", user)

        guest_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(guest_group_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path', 'parent_id',
                                                             'avatar_url', 'web_url', 'billable_members_count')
      end
    end

    context "when passing the requested hosted plan" do
      before do
        user1 = create(:user)
        user2 = create(:user)
        group = create(:group)

        group.add_owner(user)
        group.add_developer(user1)
        group.add_guest(user2)
      end

      context 'without a requested plan' do
        it 'counts guest members' do
          get api("/namespaces", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting an invalid plan' do
        it 'counts guest members' do
          get api("/namespaces?requested_hosted_plan=unknown", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting bronze plan' do
        it 'counts guest members' do
          get api("/namespaces?requested_hosted_plan=bronze", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting premium plan' do
        it 'counts guest members' do
          get api("/namespaces?requested_hosted_plan=premium", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting gold plan' do
        it 'does not count guest members' do
          get api("/namespaces?requested_hosted_plan=gold", user)

          expect(json_response.first['billable_members_count']).to eq(2)
        end
      end
    end

    context 'with gitlab subscription', :saas, :freeze_time do
      before do
        group1.add_guest(user)

        create(:gitlab_subscription, namespace: group1, max_seats_used: 1, max_seats_used_changed_at: 1.week.ago, seats_in_use: 1)
      end

      # We seem to have some N+1 queries.
      # The saml_provider association adds one for each group (saml_provider is
      #   an association on group, not namespace).
      # The route adds one for each namespace.
      # And more...
      context "avoids additional N+1 database queries" do
        let(:control) { ActiveRecord::QueryRecorder.new(skip_cached: false) { get api("/namespaces", user) } }

        before do
          create(:gitlab_subscription, namespace: group2, max_seats_used: 2)
          group2.add_guest(user)

          group3 = create(:group)
          create(:gitlab_subscription, namespace: group3, max_seats_used: 3)
          group3.add_guest(user)
        end

        it { expect { get api("/namespaces", user) }.not_to exceed_all_query_limit(control).with_threshold(8) }
      end

      it 'includes max_seats_used' do
        get api("/namespaces", user)

        expect(json_response.first['max_seats_used']).to eq(1)
      end

      it 'includes max_seats_used_changed_at' do
        get api("/namespaces", user)

        expect(Time.zone.parse(json_response.first['max_seats_used_changed_at'])).to eq(1.week.ago)
      end

      it 'includes seats_in_use' do
        get api("/namespaces", user)

        expect(json_response.first['seats_in_use']).to eq(1)
      end
    end

    context 'without gitlab subscription' do
      it 'does not include max_seats_used' do
        get api("/namespaces", user)

        json_response.each do |resp|
          expect(resp.keys).not_to include('max_seats_used')
        end
      end

      it 'does not include max_seats_used_changed_at' do
        get api("/namespaces", user)

        json_response.each do |resp|
          expect(resp.keys).not_to include('max_seats_used_changed_at')
        end
      end

      it 'does not include seats_in_use' do
        get api("/namespaces", user)

        json_response.each do |resp|
          expect(resp.keys).not_to include('seats_in_use')
        end
      end
    end
  end

  describe 'PUT /namespaces/:id' do
    let(:group1) { create(:group, :with_ci_minutes, ci_minutes_used: 1600) }

    let(:usage) do
      ::Ci::Minutes::NamespaceMonthlyUsage.current_month.find_by(namespace_id: group1)
    end

    let(:params) do
      {
        shared_runners_minutes_limit: 9001,
        additional_purchased_storage_size: 10_000,
        additional_purchased_storage_ends_on: Date.today.to_s
      }
    end

    before do
      usage.update!(notification_level: 30)
      allow(Gitlab).to receive(:com?).and_return(true)
      group1.update!(shared_runners_minutes_limit: 1000, extra_shared_runners_minutes_limit: 500)
    end

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:path) { "/namespaces/#{group1.id}" }
    end

    context 'when authenticated as admin' do
      subject { put api("/namespaces/#{group1.id}", admin, admin_mode: true), params: params }

      it 'updates namespace using full_path when full_path contains dots' do
        put api("/namespaces/#{group1.full_path}", admin, admin_mode: true), params: params

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['shared_runners_minutes_limit']).to eq(params[:shared_runners_minutes_limit])
          expect(json_response['additional_purchased_storage_size']).to eq(params[:additional_purchased_storage_size])
          expect(json_response['additional_purchased_storage_ends_on']).to eq(params[:additional_purchased_storage_ends_on])
        end
      end

      it 'updates namespace using id' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['shared_runners_minutes_limit']).to eq(params[:shared_runners_minutes_limit])
        expect(json_response['additional_purchased_storage_size']).to eq(params[:additional_purchased_storage_size])
        expect(json_response['additional_purchased_storage_ends_on']).to eq(params[:additional_purchased_storage_ends_on])
      end

      it 'expires the CI minutes CachedQuota' do
        expect_next(Gitlab::Ci::Minutes::CachedQuota).to receive(:expire!)

        subject
      end

      context 'when current CI minutes notification level is set' do
        it 'resets the current CI minutes notification level' do
          expect do
            put api("/namespaces/#{group1.id}", admin, admin_mode: true), params: params
          end.to change { usage.reload.notification_level }
             .to(Ci::Minutes::Notification::PERCENTAGES.fetch(:not_set))
        end
      end

      shared_examples 'handles monthly usage' do
        it 'expires the CI minutes CachedQuota' do
          expect_next(Gitlab::Ci::Minutes::CachedQuota).to receive(:expire!)

          subject
        end

        it 'resets the current CI minutes notification level' do
          expect do
            subject
          end.to change { usage.reload.notification_level }
            .to(Ci::Minutes::Notification::PERCENTAGES.fetch(:not_set))
        end
      end

      context 'when request has extra_shared_runners_minutes_limit param' do
        before do
          params[:extra_shared_runners_minutes_limit] = 1000
          params.delete(:shared_runners_minutes_limit)
        end

        it 'updates the extra shared runners minutes limit' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['extra_shared_runners_minutes_limit'])
            .to eq(params[:extra_shared_runners_minutes_limit])
        end

        it 'updates pending builds data since adding extra minutes the quota is not used up anymore' do
          minutes_exceeded = group1.ci_minutes_usage.minutes_used_up?
          expect(minutes_exceeded).to eq(true)

          pending_build = create(:ci_pending_build, namespace: group1, minutes_exceeded: minutes_exceeded)

          subject

          expect(pending_build.reload.minutes_exceeded).to eq(false)
        end

        it_behaves_like 'handles monthly usage'
      end

      context 'when shared_runners_minutes_limit param is present' do
        before do
          params[:shared_runners_minutes_limit] = nil
        end

        it_behaves_like 'handles monthly usage'
      end

      context 'when neither minutes limit params is provided' do
        it 'does not expire the CI minutes CachedQuota' do
          params.delete(:shared_runners_minutes_limit)
          expect(Gitlab::Ci::Minutes::CachedQuota).not_to receive(:new)

          subject
        end

        context 'when current CI minutes notification level is set' do
          it 'does not reset the current CI minutes notification level' do
            params.delete(:shared_runners_minutes_limit)

            expect do
              put api("/namespaces/#{group1.id}", admin), params: params
            end.not_to change { usage.reload.notification_level }
          end
        end
      end
    end

    context 'when not authenticated as admin' do
      it 'retuns 403' do
        put api("/namespaces/#{group1.id}", user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when namespace not found' do
      it 'returns 404' do
        put api("/namespaces/#{non_existing_record_id}", admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response).to eq('message' => '404 Namespace Not Found')
      end
    end

    context 'when project namespace is passed' do
      it 'returns 404' do
        put api("/namespaces/#{project_namespace.id}", admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response).to eq('message' => '404 Namespace Not Found')
      end
    end

    context 'when invalid params' do
      where(:attr) do
        [
          :shared_runners_minutes_limit,
          :additional_purchased_storage_size,
          :additional_purchased_storage_ends_on
        ]
      end

      with_them do
        it "returns validation error for #{attr}" do
          put api("/namespaces/#{group1.id}", admin), params: Hash[attr, 'unknown']

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end

    [:last_ci_minutes_notification_at, :last_ci_minutes_usage_notification_level].each do |attr|
      context "when namespace has a value for #{attr}" do
        before do
          group1.update_attribute(attr, Time.now)
        end

        it 'resets that value when assigning extra CI minutes' do
          expect do
            put api("/namespaces/#{group1.full_path}", admin, admin_mode: true), params: { extra_shared_runners_minutes_limit: 1000 }
          end.to change { group1.reload.send(attr) }.to(nil)
        end
      end
    end

    context "when customer purchases extra CI minutes" do
      it "ticks instance runners" do
        runners = Ci::Runner.instance_type

        put api("/namespaces/#{group1.full_path}", admin), params: { extra_shared_runners_minutes_limit: 1000 }

        expect(runners).to all(receive(:tick_runner_queue))
      end
    end

    context "when passing attributes for gitlab_subscription", :saas do
      let(:gitlab_subscription) do
        {
          start_date: '2019-06-01',
          end_date: '2020-06-01',
          plan_code: 'ultimate',
          seats: 20,
          max_seats_used: 10,
          auto_renew: true,
          trial: true,
          trial_ends_on: '2019-05-01',
          trial_starts_on: '2019-06-01',
          trial_extension_type: GitlabSubscription.trial_extension_types[:reactivated]
        }
      end

      it "creates the gitlab_subscription record" do
        expect(group1.gitlab_subscription).to be_nil

        put api("/namespaces/#{group1.id}", admin, admin_mode: true), params: {
          gitlab_subscription_attributes: gitlab_subscription
        }

        expect(group1.reload.gitlab_subscription).to have_attributes(
          start_date: Date.parse(gitlab_subscription[:start_date]),
          end_date: Date.parse(gitlab_subscription[:end_date]),
          hosted_plan: instance_of(Plan),
          seats: 20,
          max_seats_used: 10,
          auto_renew: true,
          trial: true,
          trial_starts_on: Date.parse(gitlab_subscription[:trial_starts_on]),
          trial_ends_on: Date.parse(gitlab_subscription[:trial_ends_on]),
          trial_extension_type: 'reactivated'
        )
      end

      it "updates the gitlab_subscription record" do
        existing_subscription = group1.create_gitlab_subscription!

        put api("/namespaces/#{group1.id}", admin, admin_mode: true), params: {
          gitlab_subscription_attributes: gitlab_subscription
        }

        expect(group1.reload.gitlab_subscription.reload.seats).to eq 20
        expect(group1.gitlab_subscription).to eq existing_subscription
      end

      context 'when params are invalid' do
        it 'returns a 400 error' do
          put api("/namespaces/#{group1.id}", admin, admin_mode: true), params: {
            gitlab_subscription_attributes: { start_date: nil, seats: nil }
          }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(
            "gitlab_subscription.seats" => ["can't be blank"],
            "gitlab_subscription.start_date" => ["can't be blank"]
          )
        end
      end
    end
  end

  describe 'POST :id/gitlab_subscription', :saas do
    let(:params) do
      { seats: 10,
        plan_code: 'gold',
        start_date: '01/01/2018',
        end_date: '01/01/2019' }
    end

    def do_post(current_user, payload, admin_mode: false)
      post api("/namespaces/#{group1.id}/gitlab_subscription", current_user, admin_mode: admin_mode), params: payload
    end

    it_behaves_like 'POST request permissions for admin mode' do
      let(:path) { "/namespaces/#{group1.id}/gitlab_subscription" }
    end

    context 'when authenticated as a regular user' do
      it 'returns an unauthorized error' do
        do_post(user, params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as an admin' do
      it 'fails when some attrs are missing' do
        do_post(admin, params.except(:start_date))

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'fails when the record is invalid' do
        do_post(admin, params.merge(start_date: nil), admin_mode: true)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'creates a subscription for the Group' do
        do_post(admin, params, admin_mode: true)

        expect(response).to have_gitlab_http_status(:created)
        expect(group1.gitlab_subscription).to be_present
      end

      it 'sets the trial_starts_on to the start_date' do
        do_post(admin, params.merge(trial: true), admin_mode: true)

        expect(group1.gitlab_subscription.trial_starts_on).to be_present
        expect(group1.gitlab_subscription.trial_starts_on.strftime('%d/%m/%Y')).to eq(params[:start_date])
      end

      it 'creates a subscription using full_path when the namespace path contains dots' do
        post api("/namespaces/#{group1.full_path}/gitlab_subscription", admin, admin_mode: true), params: params

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:created)
          expect(group1.gitlab_subscription).to be_present
        end
      end

      context 'when namespace does not exist' do
        it 'creates a subscription using full_path when the namespace path contains dots' do
          post api("/namespaces/#{non_existing_record_id}/gitlab_subscription", admin, admin_mode: true), params: params

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response).to eq('message' => '404 Namespace Not Found')
          end
        end
      end

      context 'when creating subscription for project namespace' do
        it 'creates a subscription using full_path when the namespace path contains dots' do
          post api("/namespaces/#{project_namespace.id}/gitlab_subscription", admin, admin_mode: true), params: params

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response).to eq('message' => '404 Namespace Not Found')
          end
        end
      end
    end
  end

  shared_examples 'authorized user using user namespace for billing' do
    it 'has access to the object' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'is successful using full_path when namespace path contains dots' do
      get api("/namespaces/#{group1.full_path}/gitlab_subscription", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'authorized user using group namespace for billing' do
    it_behaves_like 'authorized user using user namespace for billing'

    it 'returns data in a proper format' do
      expect(json_response.keys).to match_array(%w[plan usage billing])
      expect(json_response['plan'].keys).to match_array(%w[name code trial upgradable exclude_guests auto_renew])
      expect(json_response['plan']['name']).to eq('Premium')
      expect(json_response['plan']['code']).to eq('premium')
      expect(json_response['plan']['trial']).to eq(false)
      expect(json_response['plan']['upgradable']).to eq(true)
      expect(json_response['plan']['exclude_guests']).to eq(false)
      expect(json_response['usage'].keys).to match_array(%w[seats_in_subscription seats_in_use max_seats_used seats_owed])
      expect(json_response['billing'].keys).to match_array(%w[subscription_start_date subscription_end_date trial_ends_on])
    end
  end

  describe 'GET :id/gitlab_subscription', :saas do
    def do_get(current_user, namespace_id = namespace.id)
      get api("/namespaces/#{namespace_id}/gitlab_subscription", current_user)
    end

    let_it_be(:premium_plan) { create(:premium_plan) }
    let_it_be(:owner) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:auditor) { create(:auditor) }
    let_it_be(:namespace) { create(:group) }
    let_it_be(:gitlab_subscription) { create(:gitlab_subscription, hosted_plan: premium_plan, namespace: namespace) }

    before do
      namespace.add_owner(owner)
      namespace.add_maintainer(maintainer)
      namespace.add_developer(developer)
      namespace.add_guest(auditor)
    end

    context 'with a developer user' do
      context 'using a user namespace does not error' do
        before do
          do_get(developer, developer.namespace.id)
        end

        it_behaves_like 'authorized user using user namespace for billing'
      end

      it 'returns an unauthorized error' do
        do_get(developer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with a maintainer' do
      context 'using a user namespace does not error' do
        before do
          do_get(maintainer, maintainer.namespace.id)
        end

        it_behaves_like 'authorized user using user namespace for billing'
      end

      it 'returns an unauthorized error' do
        do_get(maintainer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with an auditor' do
      context 'without :auditor_billing_page_access feature flag' do
        before do
          stub_feature_flags(auditor_billing_page_access: false)
          do_get(auditor)
        end

        it 'returns an unauthorized error' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with :auditor_billing_page_access feature flag' do
        before do
          stub_feature_flags(auditor_billing_page_access: namespace)
          do_get(auditor)
        end

        it_behaves_like 'authorized user using group namespace for billing'

        context 'using a user namespace' do
          before do
            do_get(auditor, auditor.namespace.id)
          end

          it_behaves_like 'authorized user using user namespace for billing'
        end
      end
    end

    context 'with the owner of the Group' do
      before do
        do_get(owner)
      end

      it_behaves_like 'authorized user using group namespace for billing'

      context 'using a user namespace' do
        before do
          do_get(owner, owner.namespace.id)
        end

        it_behaves_like 'authorized user using user namespace for billing'
      end
    end

    context 'for groups inherits exclude_guests' do
      let_it_be(:ultimate_namespace) { create(:group) }
      let_it_be(:gitlab_subscription) { create(:gitlab_subscription, hosted_plan: ultimate_plan, namespace: ultimate_namespace) }

      before do
        ultimate_namespace.add_owner(owner)
      end

      it 'returns true for Ultimate-like plans' do
        get api("/namespaces/#{ultimate_namespace.id}/gitlab_subscription", owner)

        expect(json_response['plan']['exclude_guests']).to eq(true)
      end
    end

    context 'when namespace is a project namespace' do
      it 'returns a 404 error' do
        get api("/namespaces/#{project_namespace.id}/gitlab_subscription", admin)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response).to eq('message' => '404 Namespace Not Found')
      end
    end
  end

  describe 'PUT :id/gitlab_subscription', :saas do
    def do_put(namespace_id, current_user, payload, admin_mode: false)
      put api("/namespaces/#{namespace_id}/gitlab_subscription", current_user, admin_mode: admin_mode), params: payload
    end

    let_it_be(:premium_plan) { create(:premium_plan) }
    let_it_be(:namespace) { create(:group, name: 'test.test-group.22') }
    let_it_be(:gitlab_subscription) { create(:gitlab_subscription, namespace: namespace, start_date: '2018/01/01', end_date: '2019/01/01') }

    let(:params) do
      {
        seats: 150,
        plan_code: 'premium',
        start_date: '2018/01/01',
        end_date: '2019/01/01'
      }
    end

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:path) { "/namespaces/#{namespace.id}/gitlab_subscription" }
    end

    context 'when authenticated as a regular user' do
      it 'returns an unauthorized error' do
        do_put(namespace.id, user, { seats: 150 })

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as an admin' do
      context 'when namespace is not found' do
        it 'returns a 404 error' do
          do_put(non_existing_record_id, admin, params, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when namespace does not have a subscription' do
        let_it_be(:namespace_2) { create(:group) }

        it 'returns a 404 error' do
          do_put(namespace_2.id, admin, params, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when namespace is a project namespace' do
        it 'returns a 404 error' do
          do_put(project_namespace.id, admin, params, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response).to eq('message' => '404 Namespace Not Found')
        end
      end

      context 'when params are invalid' do
        it 'returns a 400 error' do
          do_put(namespace.id, admin, params.merge(seats: nil), admin_mode: true)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when params are valid' do
        it 'updates the subscription for the Group' do
          do_put(namespace.id, admin, params, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(gitlab_subscription.reload.seats).to eq(150)
          expect(gitlab_subscription.max_seats_used).to eq(0)
          expect(gitlab_subscription.plan_name).to eq('premium')
          expect(gitlab_subscription.plan_title).to eq('Premium')
        end

        it 'is successful using full_path when namespace path contains dots' do
          do_put(namespace.id, admin, params, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'does not clear out existing data because of defaults' do
          gitlab_subscription.update!(seats: 20, max_seats_used: 42)

          do_put(namespace.id, admin, params.except(:seats), admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(gitlab_subscription.reload).to have_attributes(
            seats: 20,
            max_seats_used: 42
          )
        end

        it 'updates the timestamp when the attributes are the same' do
          expect do
            do_put(namespace.id, admin, gitlab_subscription.attributes, admin_mode: true)
          end.to change { gitlab_subscription.reload.updated_at }
        end

        context 'when starting a new term' do
          it 'resets the seat attributes for the subscription' do
            gitlab_subscription.update!(seats: 20, max_seats_used: 42, seats_owed: 22)

            new_start = gitlab_subscription.end_date + 1.year
            new_end = new_start + 1.year
            new_term_params = params.merge(start_date: new_start, end_date: new_end)

            expect(gitlab_subscription.seats_in_use).to eq 0

            do_put(namespace.id, admin, new_term_params, admin_mode: true)

            expect(response).to have_gitlab_http_status(:ok)
            expect(gitlab_subscription.reload).to have_attributes(
              max_seats_used: 0,
              seats_owed: 0
            )
          end
        end
      end
    end

    context 'setting the trial expiration date' do
      context 'when the attr has a future date' do
        it 'updates the trial expiration date' do
          date = 30.days.from_now.to_date

          do_put(namespace.id, admin, params.merge(trial_ends_on: date), admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(gitlab_subscription.reload.trial_ends_on).to eq(date)
        end
      end
    end
  end

  describe 'POST :id/storage/limit_exclusion' do
    def do_post(namespace_id, current_user, payload, admin_mode: false)
      post api("/namespaces/#{namespace_id}/storage/limit_exclusion", current_user, admin_mode: admin_mode), params: payload
    end

    let_it_be(:namespace) { create(:group) }

    let(:params) do
      {
        reason: 'for testing reasons'
      }
    end

    context 'when on GitLab.com', :saas do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when authenticated as an admin' do
        context 'when params are valid' do
          it 'creates the exclusion for the Namespace' do
            do_post(namespace.id, admin, params, admin_mode: true)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['reason']).to eq params[:reason]
            expect(namespace.storage_limit_exclusion).not_to be nil
          end
        end

        context 'when an exclusion already exists' do
          before do
            create(:namespace_storage_limit_exclusion, namespace: namespace)
          end

          it 'returns a 400 error' do
            do_post(namespace.id, admin, params, admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response).to eq('message' => '400 Bad request - already excluded')
          end
        end

        context 'when namespace is not found' do
          it 'returns a 404 error' do
            do_post(non_existing_record_id, admin, params, admin_mode: true)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when namespace is not the root ancestor' do
          let(:subgroup) { create(:group, parent: namespace) }

          it 'returns a 400 error' do
            do_post(subgroup.id, admin, params, admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response).to eq('message' => '400 Bad request - must use a root namespace')
          end
        end

        context 'when params are invalid' do
          it 'returns a 400 error' do
            do_post(namespace.id, admin, params.merge(reason: nil), admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when unauthenticated' do
        it 'returns a 401 error' do
          do_post(namespace.id, nil, params)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when authenticated as a regular user' do
        it 'returns an unauthorized error' do
          do_post(namespace.id, user, params)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when not on GitLab.com' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: false)
      end

      it 'returns 403 error' do
        do_post(namespace.id, admin, params, admin_mode: true)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).to eq('message' => '403 Forbidden - this API is for GitLab.com only')
      end
    end
  end

  describe 'DELETE :id/storage/limit_exclusion' do
    def do_delete(namespace_id, current_user, admin_mode: false)
      delete api("/namespaces/#{namespace_id}/storage/limit_exclusion", current_user, admin_mode: admin_mode)
    end

    let_it_be(:namespace) { create(:group) }

    context 'when on GitLab.com', :saas do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when authenticated as an admin' do
        context 'when an exclusion exists' do
          let_it_be(:exclusion) { create(:namespace_storage_limit_exclusion, namespace: namespace) }

          context 'when the deletion is successful' do
            it 'returns success' do
              do_delete(namespace.id, admin, admin_mode: true)

              expect(response).to have_gitlab_http_status(:success)
              expect(namespace.storage_limit_exclusion).to be nil
            end
          end

          context 'when there is an error deleting' do
            before do
              allow_next_found_instance_of(Namespaces::Storage::LimitExclusion) do |instance|
                allow(instance).to receive(:destroy).and_return(false)
              end
            end

            it 'returns an error' do
              do_delete(namespace.id, admin, admin_mode: true)

              expect(response).to have_gitlab_http_status(:unprocessable_entity)
              expect(json_response['message']).to eq('Exclusion could not be removed')
            end
          end
        end

        context 'when namespace is not found' do
          it 'returns a 404 error' do
            do_delete(non_existing_record_id, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when namespace is not the root ancestor' do
          it 'returns a 400 error' do
            do_delete(group2.id, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response).to eq('message' => '400 Bad request - must use a root namespace')
          end
        end

        context 'when no exclusion exists' do
          it 'returns a 400 error' do
            do_delete(namespace.id, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response).to eq('message' => '400 Bad request - not excluded')
          end
        end
      end

      context 'when authenticated as a regular user' do
        it 'returns an unauthorized error' do
          do_delete(namespace.id, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when unauthenticated' do
        it 'returns a 401 error' do
          do_delete(namespace.id, nil)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when not on GitLab.com' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: false)
      end

      it 'returns 403 error' do
        do_delete(namespace.id, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).to eq('message' => '403 Forbidden - this API is for GitLab.com only')
      end
    end
  end

  describe 'GET /storage/limit_exclusions' do
    def do_get(current_user = nil, admin_mode: false)
      get api("/namespaces/storage/limit_exclusions", current_user, admin_mode: admin_mode)
    end

    context 'when on GitLab.com', :saas do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when authenticated as an admin' do
        before do
          create_list(:namespace_storage_limit_exclusion, 5)
        end

        it 'returns all limit exclusions' do
          do_get(admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:success)
          expect(response).to include_pagination_headers

          expect(json_response.size).to eq 5
        end
      end

      context 'when authenticated as a regular user' do
        it 'returns a 403 error' do
          do_get(user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when unauthenticated' do
        it 'returns a 401 error' do
          do_get

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when not on GitLab.com' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: false)
      end

      it 'returns 403 error' do
        do_get(admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response).to eq('message' => '403 Forbidden - this API is for GitLab.com only')
      end
    end
  end
end
