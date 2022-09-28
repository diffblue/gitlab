<script>
import { GlButton, GlLink, GlCollapse } from '@gitlab/ui';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  MR_APPROVALS_PROMO_DISMISSED,
  MR_APPROVALS_PROMO_I18N,
  MR_APPROVALS_PROMO_TRACKING_EVENTS,
} from '../../constants';

const trackingMixin = Tracking.mixin({});

export default {
  components: {
    GlButton,
    GlLink,
    LocalStorageSync,
    GlCollapse,
  },
  mixins: [trackingMixin],
  inject: ['learnMorePath', 'promoImageAlt', 'promoImagePath', 'tryNowPath'],
  data() {
    return {
      // isReady - used to render components after local storage has synced
      isReady: false,
      // userManuallyCollapsed - set to true if the collapsible is collapsed
      userManuallyCollapsed: false,
      // isExpanded - the current collapsible state
      isExpanded: true,
    };
  },
  computed: {
    icon() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
  },
  watch: {
    userManuallyCollapsed(isCollapsed) {
      this.isExpanded = !isCollapsed;
    },
  },
  mounted() {
    this.$nextTick(this.ready);
  },
  methods: {
    ready() {
      this.isReady = true;
    },
    toggleCollapse() {
      // If we're expanded already, then the user tried to collapse...
      if (this.isExpanded) {
        this.userManuallyCollapsed = true;

        const { action, ...options } = MR_APPROVALS_PROMO_TRACKING_EVENTS.collapsePromo;
        this.track(action, options);
      } else {
        const { action, ...options } = MR_APPROVALS_PROMO_TRACKING_EVENTS.expandPromo;
        this.track(action, options);
      }

      this.isExpanded = !this.isExpanded;
    },
  },
  trackingEvents: MR_APPROVALS_PROMO_TRACKING_EVENTS,
  i18n: MR_APPROVALS_PROMO_I18N,
  MR_APPROVALS_PROMO_DISMISSED,
};
</script>

<template>
  <div class="gl-mt-2">
    <local-storage-sync
      v-model="userManuallyCollapsed"
      :storage-key="$options.MR_APPROVALS_PROMO_DISMISSED"
    />
    <template v-if="isReady">
      <p class="gl-mb-0 gl-text-gray-500">
        {{ $options.i18n.summary }}
      </p>

      <gl-button variant="link" :icon="icon" data-testid="collapse-btn" @click="toggleCollapse">
        {{ $options.i18n.accordionTitle }}
      </gl-button>

      <gl-collapse v-model="isExpanded" class="gl-ml-5 gl-pl-2">
        <h4 class="gl-font-base gl-line-height-20 gl-mt-5 gl-mb-3">
          {{ $options.i18n.promoTitle }}
        </h4>
        <div class="gl-display-flex">
          <div class="gl-flex-grow-1 gl-max-w-62 gl-mr-5">
            <ul class="gl-list-style-position-inside gl-p-0 gl-mb-3">
              <li v-for="(statement, index) in $options.i18n.valueStatements" :key="index">
                {{ statement }}
              </li>
            </ul>
            <p>
              <gl-link
                :href="learnMorePath"
                target="_blank"
                :data-track-action="$options.trackingEvents.learnMoreClick.action"
                :data-track-label="$options.trackingEvents.learnMoreClick.label"
              >
                {{ $options.i18n.learnMore }}
              </gl-link>
            </p>
            <gl-button
              category="primary"
              variant="confirm"
              :href="tryNowPath"
              target="_blank"
              :data-track-action="$options.trackingEvents.tryNowClick.action"
              :data-track-label="$options.trackingEvents.tryNowClick.label"
              >{{ $options.i18n.tryNow }}</gl-button
            >
          </div>
          <div class="gl-flex-grow-0 gl-w-full gl-max-w-26 gl-display-none gl-md-display-block">
            <img :src="promoImagePath" :alt="promoImageAlt" class="svg gl-w-full" />
          </div>
        </div>
      </gl-collapse>
    </template>
  </div>
</template>
