<script>
import { GlButton, GlPopover, GlSprintf } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
import { removeTrialSuffix } from 'ee/billings/billings_util';
import { shouldHandRaiseLeadButtonMount } from 'ee/hand_raise_leads/hand_raise_lead';
import { formatDate } from '~/lib/utils/datetime_utility';
import { n__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import { POPOVER, RESIZE_EVENT } from './constants';

const {
  i18n,
  trackingEvents,
  trialEndDateFormatString,
  resizeEventDebounceMS,
  disabledBreakpoints,
} = POPOVER;
const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlButton,
    GlPopover,
    GlSprintf,
  },
  mixins: [trackingMixin],
  inject: {
    containerId: {},
    daysRemaining: {},
    planName: {},
    plansHref: {},
    targetId: {},
    trialEndDate: {},
    user: {},
  },
  data() {
    return {
      disabled: false,
    };
  },
  i18n,
  handRaiseLeadAttributes: {
    size: 'small',
    variant: 'confirm',
    class: 'gl-mb-3 gl-w-full',
    buttonTextClasses: 'gl-font-sm',
    href: '#',
  },
  computed: {
    formattedTrialEndDate() {
      return formatDate(this.trialEndDate, trialEndDateFormatString, true);
    },
    planNameWithoutTrial() {
      return removeTrialSuffix(this.planName);
    },
    popoverTitle() {
      const i18nPopoverTitle = n__(
        "Trials|You've got %{daysRemaining} day remaining on GitLab %{planName}!",
        "Trials|You've got %{daysRemaining} days remaining on GitLab %{planName}!",
        this.daysRemaining,
      );

      return sprintf(i18nPopoverTitle, {
        daysRemaining: this.daysRemaining,
        planName: this.planName,
      });
    },
  },
  created() {
    this.debouncedResize = debounce(() => this.updateDisabledState(), resizeEventDebounceMS);
    window.addEventListener(RESIZE_EVENT, this.debouncedResize);
  },
  mounted() {
    this.updateDisabledState();
  },
  beforeDestroy() {
    window.removeEventListener(RESIZE_EVENT, this.debouncedResize);
  },
  methods: {
    trackPageAction(eventName) {
      const { action, ...options } = trackingEvents[eventName];
      this.track(action, { ...options });
    },
    updateDisabledState() {
      this.disabled = disabledBreakpoints.includes(bp.getBreakpointSize());
    },
    onShown() {
      this.trackPageAction('popoverShown');
      shouldHandRaiseLeadButtonMount();
    },
  },
};
</script>

<template>
  <gl-popover
    ref="popover"
    placement="rightbottom"
    boundary="viewport"
    :container="containerId"
    :target="targetId"
    :disabled="disabled"
    :delay="{ hide: 400 } /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */"
    @shown="onShown"
  >
    <template #title>
      {{ popoverTitle }}
    </template>

    <gl-sprintf :message="$options.i18n.popoverContent">
      <template #bold="{ content }">
        <b>{{ sprintf(content, { trialEndDate: formattedTrialEndDate }) }}</b>
      </template>
      <template #planName>{{ planNameWithoutTrial }}</template>
    </gl-sprintf>

    <div class="gl-mt-5">
      <div data-testid="contact-sales-btn" @click="trackPageAction('contactSalesBtnClick')">
        <div
          class="js-hand-raise-lead-button"
          :data-button-attributes="JSON.stringify($options.handRaiseLeadAttributes)"
          :data-namespace-id="user.namespaceId"
          :data-user-name="user.userName"
          :data-first-name="user.firstName"
          :data-last-name="user.lastName"
          :data-company-name="user.companyName"
          :data-glm-content="user.glmContent"
        ></div>
      </div>

      <gl-button
        :href="plansHref"
        category="secondary"
        variant="confirm"
        size="small"
        class="gl-mb-0"
        block
        data-testid="compare-btn"
        :title="$options.i18n.compareAllButtonTitle"
        @click="trackPageAction('compareBtnClick')"
      >
        <span class="gl-font-sm">{{ $options.i18n.compareAllButtonTitle }}</span>
      </gl-button>
    </div>
  </gl-popover>
</template>
