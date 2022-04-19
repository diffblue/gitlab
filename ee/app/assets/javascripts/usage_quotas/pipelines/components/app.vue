<script>
import { GlButton } from '@gitlab/ui';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import { LABEL_BUY_ADDITIONAL_MINUTES } from '../constants';

export default {
  name: 'PipelineUsageApp',
  components: { GlButton },
  inject: ['namespaceActualPlanName', 'buyAdditionalMinutesPath', 'buyAdditionalMinutesTarget'],
  methods: {
    trackBuyAdditionalMinutesClick() {
      pushEECproductAddToCartEvent();
    },
  },
  LABEL_BUY_ADDITIONAL_MINUTES,
};
</script>

<template>
  <div>
    <div
      v-if="buyAdditionalMinutesPath && buyAdditionalMinutesTarget"
      class="gl-display-flex gl-justify-content-end"
    >
      <gl-button
        :href="buyAdditionalMinutesPath"
        :target="buyAdditionalMinutesTarget"
        :data-track-label="namespaceActualPlanName"
        data-track-action="click_buy_ci_minutes"
        data-track-property="pipeline_quota_page"
        data-testid="buy-additional-minutes-button"
        category="primary"
        variant="confirm"
        @click="trackBuyAdditionalMinutesClick"
      >
        {{ $options.LABEL_BUY_ADDITIONAL_MINUTES }}
      </gl-button>
    </div>
  </div>
</template>
