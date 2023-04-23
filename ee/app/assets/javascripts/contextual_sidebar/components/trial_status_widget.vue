<script>
import { GlLink, GlProgressBar } from '@gitlab/ui';
import { removeTrialSuffix } from 'ee/billings/billings_util';
import { sprintf } from '~/locale';
import Tracking from '~/tracking';
import { WIDGET } from './constants';

const { i18n, trackingEvents } = WIDGET;
const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlLink,
    GlProgressBar,
  },
  mixins: [trackingMixin],
  inject: {
    containerId: { default: null },
    trialDaysUsed: {},
    trialDuration: {},
    navIconImagePath: {},
    percentageComplete: {},
    planName: {},
    plansHref: {},
  },
  computed: {
    widgetTitle() {
      return sprintf(i18n.widgetTitle, { planName: removeTrialSuffix(this.planName) });
    },
    widgetRemainingDays() {
      return sprintf(i18n.widgetRemainingDays, {
        daysUsed: this.trialDaysUsed,
        duration: this.trialDuration,
      });
    },
  },
  methods: {
    onWidgetClick() {
      const { action, ...options } = trackingEvents.widgetClick;
      this.track(action, { ...options });
    },
  },
};
</script>

<template>
  <gl-link :id="containerId" :title="widgetTitle" :href="plansHref">
    <div
      data-testid="widget-menu"
      class="gl-display-flex gl-flex-direction-column gl-align-items-stretch gl-w-full"
      @click="onWidgetClick"
    >
      <div class="gl-display-flex gl-w-full">
        <span class="nav-icon-container svg-container gl-mr-3">
          <img :src="navIconImagePath" width="16" class="svg" />
        </span>
        <span class="nav-item-name gl-flex-grow-1">
          {{ widgetTitle }}
        </span>
        <span class="collapse-text gl-font-sm gl-mr-auto">
          {{ widgetRemainingDays }}
        </span>
      </div>
      <div class="gl-display-flex gl-align-items-stretch gl-mt-2">
        <gl-progress-bar :value="percentageComplete" class="gl-flex-grow-1" />
      </div>
    </div>
  </gl-link>
</template>
