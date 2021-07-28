<script>
import { GlButton, GlPopover, GlSprintf } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
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
  },
  data() {
    return {
      disabled: false,
      forciblyShowing: false,
      showCloseButton: false,
      show: false,
    };
  },
  i18n,
  computed: {
    formattedTrialEndDate() {
      return formatDate(this.trialEndDate, trialEndDateFormatString);
    },
    upgradeButtonTitle() {
      return sprintf(this.$options.i18n.upgradeButtonTitle, {
        groupName: this.groupName,
        planName: this.planName,
      });
    },
  },
  created() {
    this.debouncedResize = debounce(() => this.onResize(), resizeEventDebounceMS);
    window.addEventListener(RESIZE_EVENT, this.debouncedResize);

    if (this.startInitiallyShown) {
      this.forciblyShowing = true;
      this.showCloseButton = true;
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
    onClose() {
      this.forciblyShowing = false;
      this.show = false;

      const { action, ...options } = trackingEvents.closeBtnClick;
      this.track(action, { ...options, ...this.trackingPropertyAndValue() });
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
      const { action, ...options } = trackingEvents.popoverShown;
      this.track(action, { ...options, ...this.trackingPropertyAndValue() });
    },
    onUpgradeBtnClick() {
      const { action, ...options } = trackingEvents.upgradeBtnClick;
      this.track(action, { ...options, ...this.trackingPropertyAndValue() });
    },
    onCompareBtnClick() {
      const { action, ...options } = trackingEvents.compareBtnClick;
      this.track(action, { ...options, ...this.trackingPropertyAndValue() });
    },
    trackingPropertyAndValue() {
      return {
        property: this.forciblyShowing
          ? TRACKING_PROPERTY_WHEN_FORCED
          : TRACKING_PROPERTY_WHEN_VOLUNTARY,
        value: this.daysRemaining,
      };
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
    :show.sync="show"
    :triggers="forciblyShowing ? '' : 'hover focus'"
    @shown="onShown"
  >
    <template #title>
      <gl-button
        v-if="showCloseButton"
        category="tertiary"
        class="close"
        data-testid="closeBtn"
        :aria-label="$options.i18n.close"
        @click.prevent="onClose"
      >
        <span class="gl-display-inline-block" aria-hidden="true">&times;</span>
      </gl-button>
      {{ $options.i18n.popoverTitle }}
      <gl-emoji class="gl-vertical-align-baseline gl-font-size-inherit gl-ml-1" data-name="wave" />
    </template>

    <gl-sprintf :message="$options.i18n.popoverContent">
      <template #bold="{ content }">
        <b>{{ sprintf(content, { trialEndDate: formattedTrialEndDate }) }}</b>
      </template>
      <template #planName>{{ planName }}</template>
    </gl-sprintf>

    <div class="gl-mt-5">
      <gl-button
        :href="purchaseHref"
        category="primary"
        variant="confirm"
        size="small"
        class="gl-mb-0"
        block
        data-testid="upgradeBtn"
        @click="onUpgradeBtnClick"
      >
        <span class="gl-font-sm">{{ upgradeButtonTitle }}</span>
      </gl-button>

      <gl-button
        :href="plansHref"
        category="secondary"
        variant="confirm"
        size="small"
        class="gl-mb-0"
        block
        data-testid="compareBtn"
        :title="$options.i18n.compareAllButtonTitle"
        @click="onCompareBtnClick"
      >
        <span class="gl-font-sm">{{ $options.i18n.compareAllButtonTitle }}</span>
      </gl-button>
    </div>
  </gl-popover>
</template>
