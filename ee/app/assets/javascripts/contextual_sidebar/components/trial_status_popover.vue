<script>
import { GlButton, GlPopover, GlSprintf } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
import { removeTrialSuffix } from 'ee/billings/billings_util';
import { shouldHandRaiseLeadButtonMount } from 'ee/hand_raise_leads/hand_raise_lead';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import { sprintf } from '~/locale';
import Tracking from '~/tracking';
import {
  POPOVER,
  RESIZE_EVENT,
  EXPERIMENT_KEY,
  TRACKING_PROPERTY_WHEN_FORCED,
  TRACKING_PROPERTY_WHEN_VOLUNTARY,
} from './constants';

const {
  i18n,
  trackingEvents,
  trialEndDateFormatString,
  resizeEventDebounceMS,
  disabledBreakpoints,
} = POPOVER;
const trackingMixin = Tracking.mixin({ experiment: EXPERIMENT_KEY });

export default {
  components: {
    GlButton,
    GlPopover,
    GlSprintf,
    GitlabExperiment,
  },
  mixins: [trackingMixin],
  inject: {
    containerId: {},
    daysRemaining: {}, // for tracking purposes
    groupName: {},
    planName: {},
    plansHref: {},
    purchaseHref: {},
    startInitiallyShown: { default: false },
    targetId: {},
    trialEndDate: {},
    userCalloutsPath: {},
    userCalloutsFeatureId: {},
    user: {},
  },
  data() {
    return {
      disabled: false,
      forciblyShowing: false,
      show: false,
    };
  },
  i18n,
  computed: {
    formattedTrialEndDate() {
      return formatDate(this.trialEndDate, trialEndDateFormatString);
    },
    planNameWithoutTrial() {
      return removeTrialSuffix(this.planName);
    },
    upgradeButtonTitle() {
      return sprintf(this.$options.i18n.upgradeButtonTitle, {
        groupName: this.groupName,
        planName: removeTrialSuffix(this.planName),
      });
    },
    trackingPropertyAndValue() {
      return {
        property: this.forciblyShowing
          ? TRACKING_PROPERTY_WHEN_FORCED
          : TRACKING_PROPERTY_WHEN_VOLUNTARY,
        value: this.daysRemaining,
      };
    },
  },
  created() {
    this.debouncedResize = debounce(() => this.onResize(), resizeEventDebounceMS);
    window.addEventListener(RESIZE_EVENT, this.debouncedResize);

    if (this.startInitiallyShown) {
      this.forciblyShowing = true;
      this.show = true;
      this.onForciblyShown();
    }
  },
  mounted() {
    this.onResize();
  },
  beforeDestroy() {
    window.removeEventListener(RESIZE_EVENT, this.debouncedResize);
  },
  methods: {
    trackPageAction(eventName) {
      const { action, ...options } = trackingEvents[eventName];
      this.track(action, { ...options, ...this.trackingPropertyAndValue });
    },
    onClose() {
      this.forciblyShowing = false;
      this.trackPageAction('closeBtnClick');
    },
    onForciblyShown() {
      if (this.userCalloutsPath && this.userCalloutsFeatureId) {
        axios
          .post(this.userCalloutsPath, {
            feature_name: this.userCalloutsFeatureId,
          })
          .catch((e) => {
            // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
            console.error('Failed to dismiss trial status popover.', e);
          });
      }
    },
    onResize() {
      this.updateDisabledState();
    },
    onShown() {
      this.trackPageAction('popoverShown');
      shouldHandRaiseLeadButtonMount();
    },
    updateDisabledState() {
      this.disabled = disabledBreakpoints.includes(bp.getBreakpointSize());
    },
  },
};
</script>

<template>
  <gl-popover
    ref="popover"
    :container="containerId"
    :target="targetId"
    :disabled="disabled"
    placement="rightbottom"
    boundary="viewport"
    :delay="{ hide: 400 }"
    :show="show"
    :triggers="forciblyShowing ? '' : 'hover focus'"
    :show-close-button="startInitiallyShown"
    @shown="onShown"
    @close-button-clicked.prevent="onClose"
  >
    <template #title>
      {{ $options.i18n.popoverTitle }}
      <gl-emoji class="gl-vertical-align-baseline gl-font-size-inherit gl-ml-1" data-name="wave" />
    </template>

    <gl-sprintf :message="$options.i18n.popoverContent">
      <template #bold="{ content }">
        <b>{{ sprintf(content, { trialEndDate: formattedTrialEndDate }) }}</b>
      </template>
      <template #planName>{{ planNameWithoutTrial }}</template>
    </gl-sprintf>

    <div class="gl-mt-5">
      <gitlab-experiment name="group_contact_sales">
        <template #control>
          <gl-button
            ref="upgradeBtn"
            category="primary"
            variant="confirm"
            size="small"
            class="gl-mb-0"
            block
            :href="purchaseHref"
            @click="trackPageAction('upgradeBtnClick')"
          >
            <span class="gl-font-sm">{{ upgradeButtonTitle }}</span>
          </gl-button>
        </template>

        <template #candidate>
          <div data-testid="contactSalesBtn" @click="trackPageAction('contactSalesBtnClick')">
            <div
              class="js-hand-raise-lead-button"
              :data-namespace-id="user.namespaceId"
              :data-user-name="user.userName"
              :data-first-name="user.firstName"
              :data-last-name="user.lastName"
              :data-company-name="user.companyName"
              :data-glm-content="user.glmContent"
              small
            ></div>
          </div>
        </template>
      </gitlab-experiment>

      <gl-button
        :href="plansHref"
        category="secondary"
        variant="confirm"
        size="small"
        class="gl-mb-0"
        block
        data-testid="compareBtn"
        :title="$options.i18n.compareAllButtonTitle"
        @click="trackPageAction('compareBtnClick')"
      >
        <span class="gl-font-sm">{{ $options.i18n.compareAllButtonTitle }}</span>
      </gl-button>
    </div>
  </gl-popover>
</template>
