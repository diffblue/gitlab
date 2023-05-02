# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubscriptionsController, feature_category: :purchase do
  let_it_be(:user) { create(:user) }

  describe 'GET #new' do
    subject(:get_new) { get :new, params: { plan_id: 'bronze_id' } }

    context 'for unauthenticated subscription request' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to new_user_registration_path(redirect_from: 'checkout') }

      it 'stores subscription URL for later' do
        get_new

        expect(controller.stored_location_for(:user)).to eq(new_subscriptions_path(plan_id: 'bronze_id'))
      end
    end

    context 'with authenticated user' do
      before do
        sign_in(user)
      end

      it { is_expected.to render_template 'layouts/minimal' }
      it { is_expected.to render_template :new }

      context 'when there are groups eligible for the subscription' do
        let_it_be(:owned_group) { create(:group) }
        let_it_be(:sub_group) { create(:group, parent: owned_group) }
        let_it_be(:maintainer_group) { create(:group) }
        let_it_be(:developer_group) { create(:group) }

        before do
          owned_group.add_owner(user)
          maintainer_group.add_maintainer(user)
          developer_group.add_developer(user)

          allow_next_instance_of(
            GitlabSubscriptions::FetchPurchaseEligibleNamespacesService,
            user: user,
            namespaces: [owned_group],
            any_self_service_plan: true
          ) do |instance|
            allow(instance).to receive(:execute).and_return(
              instance_double(ServiceResponse, success?: true, payload: [{ namespace: owned_group, account_id: nil }])
            )
          end
        end

        it 'assigns the eligible groups for the subscription' do
          get_new

          expect(assigns(:eligible_groups)).to match_array [owned_group]
        end

        context 'and request specify which group to use' do
          it 'assign requested group' do
            get :new, params: { namespace_id: owned_group.id }

            expect(assigns(:namespace)).to eq(owned_group)
          end
        end

        context 'request does not specify namespace' do
          it 'falls back to users namespace' do
            get_new

            expect(assigns(:namespace)).to eq(user.namespace)
          end
        end
      end

      context 'when there are no eligible groups for the subscription' do
        let_it_be(:group) { create(:group) }

        it 'assigns eligible groups as an empty array if CustomerDot returns empty payload' do
          group.add_owner(user)

          expect_next_instance_of(
            GitlabSubscriptions::FetchPurchaseEligibleNamespacesService,
            user: user,
            namespaces: [group],
            any_self_service_plan: true
          ) do |instance|
            allow(instance).to receive(:execute).and_return(instance_double(ServiceResponse, success?: true, payload: []))
          end

          get_new

          expect(assigns(:eligible_groups)).to eq []
        end

        it 'assigns eligible groups as an empty array if user is not owner of any groups' do
          get_new

          expect(assigns(:eligible_groups)).to eq []
        end
      end
    end
  end

  describe 'GET #buy_minutes' do
    let_it_be(:group) { create(:group) }
    let_it_be(:plan_id) { 'ci_minutes' }

    subject(:buy_minutes) { get :buy_minutes, params: { selected_group: group.id } }

    context 'with authenticated user' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      context 'when the add-on plan cannot be found' do
        let_it_be(:group) { create(:group) }

        before do
          group.add_owner(user)

          allow(Gitlab::SubscriptionPortal::Client)
            .to receive(:get_plans).with(tags: ['CI_1000_MINUTES_PLAN'])
            .and_return({ success: false, data: [] })
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when there are groups eligible for the addon' do
        let_it_be(:group) { create(:group) }

        before do
          group.add_owner(user)

          allow(Gitlab::SubscriptionPortal::Client)
            .to receive(:get_plans).with(tags: ['CI_1000_MINUTES_PLAN'])
            .and_return({ success: true, data: [{ 'id' => 'ci_minutes' }] })

          allow_next_instance_of(
            GitlabSubscriptions::FetchPurchaseEligibleNamespacesService,
            user: user,
            plan_id: 'ci_minutes',
            namespaces: [group]
          ) do |instance|
            allow(instance).to receive(:execute).and_return(
              instance_double(ServiceResponse, success?: true, payload: [{ namespace: group, account_id: nil }])
            )
          end
        end

        it { is_expected.to render_template 'layouts/minimal' }
        it { is_expected.to render_template :buy_minutes }

        it 'assigns the group for the addon' do
          buy_minutes

          expect(assigns(:group)).to eq group
          expect(assigns(:account_id)).to eq nil
        end
      end
    end
  end

  describe 'GET #buy_storage' do
    let_it_be(:group) { create(:group) }

    subject(:buy_storage) { get :buy_storage, params: { selected_group: group.id } }

    context 'with authenticated user' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      context 'when the add-on plan cannot be found' do
        let_it_be(:group) { create(:group) }

        before do
          group.add_owner(user)

          allow(Gitlab::SubscriptionPortal::Client)
            .to receive(:get_plans).with(tags: ['STORAGE_PLAN'])
            .and_return({ success: false, data: [] })
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when there are groups eligible for the addon' do
        let_it_be(:group) { create(:group) }

        before do
          group.add_owner(user)

          allow(Gitlab::SubscriptionPortal::Client)
            .to receive(:get_plans).with(tags: ['STORAGE_PLAN'])
            .and_return({ success: true, data: [{ 'id' => 'storage' }] })

          allow_next_instance_of(
            GitlabSubscriptions::FetchPurchaseEligibleNamespacesService,
            user: user,
            plan_id: 'storage',
            namespaces: [group]
          ) do |instance|
            allow(instance).to receive(:execute).and_return(
              instance_double(ServiceResponse, success?: true, payload: [{ namespace: group, account_id: nil }])
            )
          end
        end

        it { is_expected.to render_template 'layouts/minimal' }
        it { is_expected.to render_template :buy_storage }

        it 'assigns the group for the addon' do
          buy_storage

          expect(assigns(:group)).to eq group
          expect(assigns(:account_id)).to eq nil
        end
      end
    end
  end

  describe 'GET #payment_form' do
    subject { get :payment_form, params: { id: 'cc' } }

    context 'with unauthorized user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with authorized user' do
      before do
        sign_in(user)
        client_response = { success: true, data: { signature: 'x', token: 'y' } }
        allow(Gitlab::SubscriptionPortal::Client).to receive(:payment_form_params).with('cc').and_return(client_response)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'returns the data attribute of the client response in JSON format' do
        subject
        expect(response.body).to eq('{"signature":"x","token":"y"}')
      end
    end
  end

  describe 'GET #payment_method' do
    subject { get :payment_method, params: { id: 'xx' } }

    context 'with unauthorized user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with authorized user' do
      before do
        sign_in(user)
        client_response = { success: true, data: { credit_card_type: 'Visa' } }
        allow(Gitlab::SubscriptionPortal::Client).to receive(:payment_method).with('xx').and_return(client_response)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'returns the data attribute of the client response in JSON format' do
        subject
        expect(response.body).to eq('{"credit_card_type":"Visa"}')
      end
    end
  end

  describe 'GET #validate_payment_method' do
    let(:params) { { id: 'foo', gitlab_user_id: 'user-id' } }

    subject do
      post :validate_payment_method, params: params, as: :json
    end

    context 'with unauthorized user' do
      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'with authorized user' do
      before do
        sign_in(user)
        expect(Gitlab::SubscriptionPortal::Client)
          .to receive(:validate_payment_method)
          .with(params[:id], { gitlab_user_id: params[:gitlab_user_id] })
          .and_return({ success: true })
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it { is_expected.to be_successful }
    end
  end

  describe 'POST #create', :snowplow do
    subject do
      post :create,
        params: params,
        as: :json
    end

    let(:params) do
      {
        setup_for_company: setup_for_company,
        customer: { company: 'My company', country: 'NL' },
        subscription: { plan_id: 'x', quantity: 2, source: 'some_source' }
      }
    end

    let(:setup_for_company) { true }

    context 'with unauthorized user' do
      it { is_expected.to have_gitlab_http_status(:unauthorized) }
    end

    context 'with authorized user' do
      let_it_be(:service_response) { { success: true, data: 'foo' } }
      let_it_be(:group) { create(:group) }

      before do
        sign_in(user)
        allow_next_instance_of(GitlabSubscriptions::CreateService) do |instance|
          allow(instance).to receive(:execute).and_return(service_response)
        end
        allow_next_instance_of(Groups::CreateService) do |instance|
          allow(instance).to receive(:execute).and_return(group)
        end
      end

      context 'when setting up for a company' do
        it 'updates the setup_for_company attribute of the current user' do
          expect { subject }.to change { user.reload.setup_for_company }.from(nil).to(true)
        end

        it 'creates a group based on the company' do
          expect(Namespace).to receive(:clean_name).with(params.dig(:customer, :company)).and_call_original
          expect_next_instance_of(Groups::CreateService) do |instance|
            expect(instance).to receive(:execute)
          end

          subject
        end
      end

      context 'when using a promo code' do
        let(:params) do
          {
            setup_for_company: setup_for_company,
            customer: { company: 'My company', country: 'NL' },
            subscription: { plan_id: 'x', quantity: 2, source: 'some_source', promo_code: 'Sample promo code' }
          }
        end

        it 'creates subscription using promo code' do
          expect_next_instance_of(GitlabSubscriptions::CreateService,
            user,
            group: group,
            customer_params: ActionController::Parameters.new(params[:customer]).permit!,
            subscription_params: ActionController::Parameters.new(params[:subscription]).permit!
          ) do |instance|
            expect(instance).to receive(:execute).and_return(service_response)
          end

          subject
        end
      end

      context 'when not setting up for a company' do
        let(:params) do
          {
            setup_for_company: setup_for_company,
            customer: { country: 'NL' },
            subscription: { plan_id: 'x', quantity: 1, source: 'some_source' }
          }
        end

        let(:setup_for_company) { false }

        it 'does not update the setup_for_company attribute of the current user' do
          expect { subject }.not_to change { user.reload.setup_for_company }
        end

        it 'creates a group based on the user' do
          expect(Namespace).to receive(:clean_name).with(user.name).and_call_original
          expect_next_instance_of(Groups::CreateService) do |instance|
            expect(instance).to receive(:execute)
          end

          subject
        end
      end

      context 'when an error occurs creating a group' do
        let(:group) { Group.new(path: 'foo') }

        it 'returns the errors in json format' do
          group.valid?
          subject

          expect(response.body).to include({ name: ["can't be blank"] }.to_json)
        end

        context 'when invalid name is passed' do
          let(:group) { Group.new(path: 'foo', name: '<script>alert("attack")</script>') }

          it 'returns the errors in json format' do
            group.valid?
            subject

            expect(Gitlab::Json.parse(response.body)['name']).to match_array([Gitlab::Regex.group_name_regex_message, HtmlSafetyValidator.error_message])
          end

          it 'tracks errors' do
            group.valid?
            subject

            expect_snowplow_event(
              category: 'SubscriptionsController',
              label: 'confirm_purchase',
              action: 'click_button',
              property: group.errors.full_messages.to_s,
              user: user,
              namespace: nil
            )
          end
        end
      end

      context 'on successful creation of a subscription' do
        it { is_expected.to have_gitlab_http_status(:ok) }

        it 'returns the group edit location in JSON format' do
          subject

          expect(response.body).to eq({ location: "/-/subscriptions/groups/#{group.path}/edit?plan_id=x&quantity=2" }.to_json)
        end
      end

      context 'on unsuccessful creation of a subscription' do
        let(:service_response) { { success: false, data: { errors: 'error message' } } }

        it { is_expected.to have_gitlab_http_status(:ok) }

        it 'returns the error message in JSON format' do
          subject

          expect(response.body).to eq('{"errors":"error message"}')
          expect_snowplow_event(
            category: 'SubscriptionsController',
            label: 'confirm_purchase',
            action: 'click_button',
            property: 'error message',
            user: user,
            namespace: group
          )
        end
      end

      context 'when selecting an existing group' do
        let(:params) do
          {
            selected_group: selected_group.id,
            customer: { country: 'NL' },
            subscription: { plan_id: 'x', quantity: 1, source: 'another_source' },
            redirect_after_success: redirect_after_success
          }
        end

        let_it_be(:redirect_after_success) { nil }

        context 'when the selected group is eligible for a new subscription' do
          let_it_be(:selected_group) { create(:group) }

          before do
            selected_group.add_owner(user)

            allow_next_instance_of(
              GitlabSubscriptions::FetchPurchaseEligibleNamespacesService,
              user: user,
              plan_id: params[:subscription][:plan_id],
              namespaces: [selected_group]
            ) do |instance|
              allow(instance)
                .to receive(:execute)
                .and_return(
                  instance_double(ServiceResponse, success?: true, payload: [{ namespace: selected_group, account_id: nil }])
                )
            end

            gitlab_plans_url = ::Gitlab::Routing.url_helpers.subscription_portal_gitlab_plans_url

            stub_request(:get, "#{gitlab_plans_url}?plan=free&namespace_id=")
          end

          it 'does not create a group' do
            expect { subject }.to not_change { Group.count }
          end

          it 'returns the selected group location in JSON format' do
            subject

            plan_id = params[:subscription][:plan_id]
            quantity = params[:subscription][:quantity]

            expect(response.body).to eq({ location: "#{group_billings_path(selected_group)}?plan_id=#{plan_id}&purchased_quantity=#{quantity}" }.to_json)
          end

          context 'when having an explicit redirect' do
            let_it_be(:redirect_after_success) { '/-/path/to/redirect' }

            it { is_expected.to have_gitlab_http_status(:ok) }

            it 'returns the provided redirect path as location' do
              subject

              expect(response.body).to eq({ location: redirect_after_success }.to_json)
            end

            it 'tracks the creation of the subscriptions' do
              subject

              expect_snowplow_event(
                category: 'SubscriptionsController',
                label: 'confirm_purchase',
                action: 'click_button',
                property: 'Success: subscription',
                namespace: selected_group,
                user: user
              )
            end
          end

          context 'purchasing an addon' do
            before do
              params[:subscription][:is_addon] = true
            end

            it 'tracks creation with add-on success message' do
              subject

              expect_snowplow_event(
                category: 'SubscriptionsController',
                label: 'confirm_purchase',
                action: 'click_button',
                property: 'Success: add-on',
                namespace: selected_group,
                user: user
              )
            end
          end
        end

        context 'when the selected group is ineligible for a new subscription' do
          let_it_be(:selected_group) { create(:group) }

          before do
            selected_group.add_owner(user)

            allow_next_instance_of(
              GitlabSubscriptions::FetchPurchaseEligibleNamespacesService,
              user: user,
              plan_id: params[:subscription][:plan_id],
              namespaces: [selected_group]
            ) do |instance|
              allow(instance)
                .to receive(:execute)
                .and_return(instance_double(ServiceResponse, success?: true, payload: []))
            end
          end

          it 'does not create a group' do
            expect { subject }.to not_change { Group.count }
          end

          it 'returns a 404 not found' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when selected group is a sub group' do
          let(:selected_group) { create(:group, parent: create(:group)) }

          it { is_expected.to have_gitlab_http_status(:not_found) }
        end
      end

      context 'when selecting a non existing group' do
        let(:params) do
          {
            selected_group: non_existing_record_id,
            customer: { country: 'NL' },
            subscription: { plan_id: 'x', quantity: 1, source: 'new_source' }
          }
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when selecting a group without owner role' do
        let(:params) do
          {
            selected_group: create(:group).id,
            customer: { country: 'NL' },
            subscription: { plan_id: 'x', quantity: 1, source: 'new_source' }
          }
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
