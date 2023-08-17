# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GitlabSubscriptions::AddOnPurchases, :aggregate_failures, feature_category: :saas_provisioning do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:purchase_xid) { 'S-A00000001' }
  let(:namespace_id) { namespace.id }
  let(:add_on_name) { add_on.name }

  shared_examples 'not found error' do
    it 'returns :not_found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'API endpoint pre-checks' do
    context 'when the namespace cannot be found' do
      let(:namespace_id) { non_existing_record_id }

      it_behaves_like 'not found error'
    end

    context 'when the add-on cannot be found' do
      let(:add_on_name) { 'non-existing-add-on' }

      it_behaves_like 'not found error'
    end
  end

  describe 'POST /namespaces/:id/subscription_add_on_purchase/:add_on_name' do
    let(:params) do
      {
        quantity: 10,
        expires_on: (Date.current + 1.year).to_s,
        purchase_xid: purchase_xid
      }
    end

    subject(:post_add_on_purchase) do
      post api(
        "/namespaces/#{namespace_id}/subscription_add_on_purchase/#{add_on_name}",
        user,
        admin_mode: admin_mode
      ),
        params: params
    end

    context 'with a non-admin user' do
      let_it_be(:admin_mode) { false }
      let_it_be(:user) { create(:user) }

      it 'returns :forbidden' do
        post_add_on_purchase

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with admin user' do
      let_it_be(:admin_mode) { true }
      let_it_be(:user) { admin }

      include_examples 'API endpoint pre-checks'

      context 'when the add-on purchase does not exist' do
        it 'creates a new add-on purchase' do
          expect { post_add_on_purchase }.to change { GitlabSubscriptions::AddOnPurchase.count }

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['namespace_id']).to eq(namespace_id)
          expect(json_response['namespace_name']).to eq(namespace.name)
          expect(json_response['add_on']).to eq(add_on.name.titleize)
          expect(json_response['quantity']).to eq(params[:quantity])
          expect(json_response['expires_on']).to eq(params[:expires_on])
          expect(json_response['purchase_xid']).to eq(params[:purchase_xid])
        end

        context 'when the add-on purchase cannot be saved' do
          let(:params) { super().merge(quantity: 0) }

          it 'returns an error' do
            post_add_on_purchase

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to include('"quantity":["must be greater than or equal to 1"]')
            expect(json_response['quantity']).not_to eq(10)
          end
        end
      end

      context 'when the add-on purchase already exists' do
        before do
          create(
            :gitlab_subscription_add_on_purchase,
            namespace: namespace,
            add_on: add_on,
            quantity: 5,
            purchase_xid: purchase_xid
          )
        end

        it 'does not create a new add-on purchase and does not update the existing one' do
          expect { post_add_on_purchase }.not_to change { GitlabSubscriptions::AddOnPurchase.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include(
            "Add-on purchase for namespace #{namespace.name} and add-on #{add_on.name.titleize} already exists, " \
            'update the existing record'
          )
          expect(json_response['quantity']).not_to eq(10)
        end
      end
    end
  end

  describe 'GET /namespaces/:id/subscription_add_on_purchase/:add_on_name' do
    subject(:get_add_on_purchase) do
      get api(
        "/namespaces/#{namespace_id}/subscription_add_on_purchase/#{add_on_name}",
        user,
        admin_mode: admin_mode
      )
    end

    context 'with a non-admin user' do
      let_it_be(:admin_mode) { false }
      let_it_be(:user) { create(:user) }

      it 'returns :forbidden' do
        get_add_on_purchase

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with admin user' do
      let_it_be(:admin_mode) { true }
      let_it_be(:user) { admin }

      include_examples 'API endpoint pre-checks'

      context 'when the add-on purchase does not exist' do
        it_behaves_like 'not found error'
      end

      context 'when the add-on purchase exists' do
        it 'returns the found add-on purchase' do
          add_on_purchase = create(
            :gitlab_subscription_add_on_purchase,
            namespace: namespace,
            add_on: add_on,
            quantity: 5,
            purchase_xid: purchase_xid
          )

          get_add_on_purchase

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response).to eq(
            'namespace_id' => namespace_id,
            'namespace_name' => namespace.name,
            'add_on' => add_on.name.titleize,
            'quantity' => add_on_purchase.quantity,
            'expires_on' => add_on_purchase.expires_on.to_s,
            'purchase_xid' => add_on_purchase.purchase_xid
          )
        end
      end
    end
  end

  describe 'PUT /namespaces/:id/subscription_add_on_purchase/:add_on_name' do
    let(:params) do
      {
        quantity: 10,
        expires_on: (Date.current + 1.year).to_s,
        purchase_xid: purchase_xid
      }
    end

    subject(:put_add_on_purchase) do
      put api(
        "/namespaces/#{namespace_id}/subscription_add_on_purchase/#{add_on_name}",
        user,
        admin_mode: admin_mode
      ),
        params: params
    end

    context 'with a non-admin user' do
      let_it_be(:admin_mode) { false }
      let_it_be(:user) { create(:user) }

      it 'returns :forbidden' do
        put_add_on_purchase

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with admin user' do
      let_it_be(:admin_mode) { true }
      let_it_be(:user) { admin }

      include_examples 'API endpoint pre-checks'

      context 'when the add-on purchase exists' do
        let_it_be(:expires_on) { Date.current + 6.months }
        let_it_be_with_reload(:add_on_purchase) do
          create(
            :gitlab_subscription_add_on_purchase,
            namespace: namespace,
            add_on: add_on,
            quantity: 5,
            expires_on: expires_on,
            purchase_xid: purchase_xid
          )
        end

        it 'updates the found add-on purchase' do
          expect do
            put_add_on_purchase
            add_on_purchase.reload
          end.to change { add_on_purchase.quantity }.from(5).to(10)
            .and change { add_on_purchase.expires_on }.from(expires_on).to(params[:expires_on].to_date)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response).to eq(
            'namespace_id' => namespace_id,
            'namespace_name' => namespace.name,
            'add_on' => add_on.name.titleize,
            'quantity' => params[:quantity],
            'expires_on' => params[:expires_on],
            'purchase_xid' => params[:purchase_xid]
          )
        end

        context 'with only required params' do
          let(:params) { { expires_on: (Date.current + 1.year).to_s } }

          it 'updates the add-on purchase' do
            expect do
              put_add_on_purchase
              add_on_purchase.reload
            end.to change { add_on_purchase.expires_on }.from(expires_on).to(params[:expires_on].to_date)
              .and not_change { add_on_purchase.quantity }

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response).to eq(
              'namespace_id' => namespace_id,
              'namespace_name' => namespace.name,
              'add_on' => add_on.name.titleize,
              'quantity' => add_on_purchase.quantity,
              'expires_on' => params[:expires_on],
              'purchase_xid' => add_on_purchase.purchase_xid
            )
          end
        end

        context 'when the add-on purchase cannot be saved' do
          let(:params) { super().merge(quantity: 0) }

          it 'returns an error' do
            put_add_on_purchase

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to include('"quantity":["must be greater than or equal to 1"]')
          end
        end
      end

      context 'when the add-on purchase does not exist' do
        it 'returns an error' do
          put_add_on_purchase

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include(
            "Add-on purchase for namespace #{namespace.name} and add-on #{add_on.name.titleize} does not exist, " \
            'create a new record instead'
          )
        end
      end
    end
  end
end
