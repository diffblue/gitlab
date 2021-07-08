<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import Api from 'ee/api';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import activeStepQuery from 'ee/vue_shared/purchase_flow/graphql/queries/active_step.query.graphql';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  data() {
    return {
      isActive: false,
      isLoading: false,
    };
  },
  apollo: {
    isActive: {
      query: activeStepQuery,
      update: ({ activeStep }) => activeStep?.id === STEPS[3].id,
      error: (error) => {
        createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
      },
    },
    confirmOrderParams: {
      query: stateQuery,
      update(data) {
        const { customer } = data;

        return {
          setup_for_company: data.isSetupForCompany,
          selected_group: data.subscription.namespaceId,
          new_user: data.isNewUser,
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
            plan_id: data.selectedPlanId,
            payment_method_id: data.paymentMethod.id,
            quantity: data.subscription.quantity,
          },
        };
      },
    },
  },
  methods: {
    confirmOrder() {
      this.isLoading = true;

      return Api.confirmOrder(this.confirmOrderParams)
        .then(({ data }) => {
          if (data.location) {
            redirectTo(data.location);
          } else {
            throw new Error(JSON.stringify(data.errors));
          }
        })
        .catch((error) =>
          createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true }),
        )
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
  <div v-if="isActive" class="full-width gl-mb-7">
    <gl-button :disabled="isLoading" variant="success" category="primary" @click="confirmOrder">
      <gl-loading-icon v-if="isLoading" inline size="sm" />
      {{ isLoading ? $options.i18n.confirming : $options.i18n.confirm }}
    </gl-button>
  </div>
</template>
