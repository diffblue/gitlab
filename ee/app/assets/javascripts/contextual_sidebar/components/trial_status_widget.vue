<script>
import { GlLink, GlProgressBar, GlIcon } from '@gitlab/ui';
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
    GlIcon,
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
  i18n,
  computed: {
    isTrialActive() {
      return this.percentageComplete <= 100;
    },
    widgetTitle() {
      if (this.isTrialActive) {
        return sprintf(i18n.widgetTitle, { planName: removeTrialSuffix(this.planName) });
      }
      return i18n.widgetTitleExpiredTrial;
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
      const options = this.isTrialActive
        ? trackingEvents.activeTrialOptions
        : trackingEvents.trialEndedOptions;

      this.track(trackingEvents.action, { ...options });
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
      <div v-if="isTrialActive">
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
      <div v-else class="gl-display-flex gl-gap-5 gl-w-full gl-px-2">
        <gl-icon name="information-o" class="gl-text-blue-600!" />
        <div>
          <div class="gl-font-weight-bold">
            {{ widgetTitle }}
          </div>
          <div class="gl-mt-3">
            {{ $options.i18n.widgetBodyExpiredTrial }}
          </div>
        </div>
      </div>
    </div>
  </gl-link>
</template>
