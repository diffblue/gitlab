<script>
import { GlButton } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import Tracking from '~/tracking';
import { EXPLORE_PAID_PLANS_CLICKED } from '../constants';

export default {
  name: 'SubscriptionUpgradeInfoCard',
  components: { GlButton },
  mixins: [Tracking.mixin()],
  props: {
    maxNamespaceSeats: {
      type: Number,
      required: true,
    },
    explorePlansPath: {
      type: String,
      required: true,
    },
    activeTrial: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    description: s__(
      'Billing|To ensure all members can access the group when your trial ends, you can upgrade to a paid tier.',
    ),
    cta: s__('Billing|Explore paid plans'),
  },
  computed: {
    title() {
      if (this.activeTrial) {
        return s__('Billing|Unlimited members during your trial');
      }

      return n__(
        'Billing|Groups in the Free tier are limited to %d seat',
        'Billing|Groups in the Free tier are limited to %d seats',
        this.maxNamespaceSeats,
      );
    },
  },
  methods: {
    trackClick() {
      this.track('click_button', { label: EXPLORE_PAID_PLANS_CLICKED });
    },
  },
};
</script>

<template>
  <div class="gl-bg-white gl-border-1 gl-border-gray-100 gl-border-solid gl-p-5 gl-rounded-base">
    <div class="gl-display-flex gl-sm-flex-direction-column">
      <div class="gl-mb-3 gl-md-mb-0 gl-md-mr-5 gl-sm-mr-0">
        <p class="gl-font-weight-bold gl-mb-3" data-testid="title">
          {{ title }}
        </p>
        <p class="gl-m-0" data-testid="description">
          {{ $options.i18n.description }}
        </p>
      </div>
      <div>
        <gl-button
          :href="explorePlansPath"
          category="primary"
          variant="confirm"
          @click="trackClick"
        >
          {{ $options.i18n.cta }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
