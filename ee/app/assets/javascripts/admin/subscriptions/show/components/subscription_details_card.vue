<script>
import { GlCard } from '@gitlab/ui';
import { identity } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { getLicenseTypeLabel } from '../utils';
import SubscriptionDetailsTable from './subscription_details_table.vue';

const subscriptionDetailsFormatRules = {
  id: getIdFromGraphQLId,
  expiresAt: getTimeago().format,
  lastSync: getTimeago().format,
  type: getLicenseTypeLabel,
  plan: capitalizeFirstCharacter,
};

export default {
  name: 'SubscriptionDetailsCard',
  components: {
    GlCard,
    SubscriptionDetailsTable,
  },
  props: {
    detailsFields: {
      type: Array,
      required: true,
    },
    headerText: {
      type: String,
      required: false,
      default: '',
    },
    subscription: {
      type: Object,
      required: true,
    },
    syncDidFail: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    details() {
      return this.detailsFields.map((detail) => {
        const formatter = subscriptionDetailsFormatRules[detail] || identity;
        const valueToFormat = this.subscription[detail];
        const value = valueToFormat ? formatter(valueToFormat) : '';
        return { detail, value };
      });
    },
  },
};
</script>

<template>
  <gl-card>
    <template v-if="headerText" #header>
      <h6 class="gl-m-0">{{ headerText }}</h6>
    </template>
    <subscription-details-table :details="details" :sync-did-fail="syncDidFail" />
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-card>
</template>
