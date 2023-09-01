<script>
import { v4 as uuid } from 'uuid';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import Api from 'ee/api';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { s__ } from '~/locale';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  data() {
    return {
      idempotencyKey: uuid(),
      isActive: false,
      isLoading: false,
      orderParams: {},
    };
  },
  computed: {
    confirmOrderParams() {
      return { ...this.orderParams, idempotency_key: this.idempotencyKey };
    },
    idempotencyKeyParams() {
      return [this.paymentMethodId, this.planId, this.quantity, this.selectedGroup, this.zipCode];
    },
    paymentMethodId() {
      return this.orderParams?.subscription?.payment_method_id;
    },
    planId() {
      return this.orderParams?.subscription?.plan_id;
    },
    quantity() {
      return this.orderParams?.subscription?.quantity;
    },
    selectedGroup() {
      return this.orderParams?.selected_group;
    },
    zipCode() {
      return this.orderParams?.customer?.zip_code;
    },
  },
  watch: {
    idempotencyKeyParams: {
      handler() {
        this.idempotencyKey = uuid();
      },
    },
  },
  apollo: {
    isActive: {
      query: activeStepQuery,
      update: ({ activeStep }) => activeStep?.id === STEPS[3].id,
      error: (error) => {
        this.$emit(PurchaseEvent.ERROR, error);
      },
    },
    orderParams: {
      query: stateQuery,
      skip() {
        return !this.isActive;
      },
      update(data) {
        const { customer } = data;
        const { name } = data.activeSubscription;
        return {
          setup_for_company: data.isSetupForCompany,
          selected_group: data.selectedNamespaceId,
          new_user: data.isNewUser,
          redirect_after_success: data.redirectAfterSuccess,
          active_subscription: name,
          customer: {
            country: customer.country,
            address_1: customer.address1,
            address_2: customer.address2,
            city: customer.city,
            state: customer.state,
            zip_code: customer.zipCode,
            company: customer.company,
          },
          subscription: {
            quantity: data.subscription.quantity,
            is_addon: data.selectedPlan.isAddon,
            plan_id: data.selectedPlan.id,
            payment_method_id: data.paymentMethod.id,
          },
        };
      },
    },
  },
  methods: {
    isClientSideError(status) {
      return status >= 400 && status < 500;
    },
    confirmOrder() {
      this.isLoading = true;
      return Api.confirmOrder(this.confirmOrderParams)
        .then(({ data }) => {
          if (data?.location) {
            redirectTo(data.location); // eslint-disable-line import/no-deprecated
            return;
          }
          if (data?.errors) {
            throw new Error(JSON.stringify(data.errors));
          }
        })
        .catch((error) => {
          const { status } = error?.response || {};
          // Regenerate the idempotency key on client-side errors, to ensure the server regards the new request.
          // Context: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129830#note_1522796835.
          if (this.isClientSideError(status)) {
            this.idempotencyKey = uuid();
          }
          this.$emit(PurchaseEvent.ERROR, error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
  i18n: {
    confirm: s__('Checkout|Confirm purchase'),
    confirming: s__('Checkout|Confirming...'),
  },
};
</script>
<template>
  <div v-if="isActive" class="full-width gl-mb-7" data-testid="confirm-order-root">
    <gl-button :disabled="isLoading" variant="confirm" category="primary" @click="confirmOrder">
      <gl-loading-icon v-if="isLoading" inline size="sm" />
      {{ isLoading ? $options.i18n.confirming : $options.i18n.confirm }}
    </gl-button>
  </div>
</template>
