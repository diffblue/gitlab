<script>
import { GlLink, GlButton, GlSprintf } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import Tracking from '~/tracking';
import { EXPLORE_PAID_PLANS_CLICKED } from '../constants';

export default {
  name: 'SubscriptionUpgradeInfoCard',
  components: { GlLink, GlButton, GlSprintf },
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
  },
  i18n: {
    title: s__('Billing|Free groups on GitLab are limited to %{maxNamespaceSeats} seats'),
    description: s__(
      'Billing|%{overLimitMessage} To ensure all members (active and %{linkStart}over limit%{linkEnd}) can access the group, you can start a trial or upgrade to a paid tier.',
    ),
    cta: s__('Billing|Explore all plans'),
  },
  overLimitLink: 'https://about.gitlab.com/blog/2022/03/24/efficient-free-tier/',
  computed: {
    overLimitMessage() {
      return n__(
        'Billing|If the group has over %d member, only those occupying a seat can access the group.',
        'Billing|If the group has over %d members, only those occupying a seat can access the group.',
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
          <gl-sprintf :message="$options.i18n.title">
            <template #maxNamespaceSeats>{{ maxNamespaceSeats }}</template>
          </gl-sprintf>
        </p>
        <p class="gl-m-0" data-testid="description">
          <gl-sprintf :message="$options.i18n.description">
            <template #overLimitMessage>{{ overLimitMessage }}</template>
            <template #link="{ content }">
              <gl-link :href="$options.overLimitLink" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
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
