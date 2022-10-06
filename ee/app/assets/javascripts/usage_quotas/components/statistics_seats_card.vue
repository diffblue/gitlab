<script>
import { GlLink, GlIcon, GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'StatisticsSeatsCard',
  components: { GlLink, GlIcon, GlButton },
  i18n: {
    seatsUsedText: __('Max seats used'),
    seatsUsedHelpText: __('Learn more about max seats used'),
    seatsOwedText: __('Seats owed'),
    seatsOwedHelpText: __('Learn more about seats owed'),
    addSeatsText: s__('Billing|Add seats'),
  },
  helpLinks: {
    seatsOwedLink: helpPagePath('subscriptions/gitlab_com/index', { anchor: 'seats-owed' }),
    seatsUsedLink: helpPagePath('subscriptions/gitlab_com/index', {
      anchor: 'view-your-gitlab-saas-subscription',
    }),
  },
  props: {
    /**
     * Number of seats used
     */
    seatsUsed: {
      type: Number,
      required: false,
      default: null,
    },
    /**
     * Number of seats owed
     */
    seatsOwed: {
      type: Number,
      required: false,
      default: null,
    },
    /**
     * Link for purchase seats button
     */
    purchaseButtonLink: {
      type: String,
      required: false,
      default: null,
    },
    /**
     * Text for the purchase seats button
     */
    purchaseButtonText: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    shouldRenderSeatsUsedBlock() {
      return this.seatsUsed !== null;
    },
    shouldRenderSeatsOwedBlock() {
      return this.seatsOwed !== null;
    },
  },
};
</script>

<template>
  <div
    class="gl-bg-white gl-border-1 gl-border-gray-100 gl-border-solid gl-p-5 gl-rounded-base gl-display-flex"
  >
    <div class="gl-flex-grow-1">
      <p
        v-if="shouldRenderSeatsUsedBlock"
        class="gl-font-size-h-display gl-font-weight-bold gl-mb-3"
        data-testid="seats-used-block"
        data-qa-selector="seats_used"
      >
        <span class="gl-relative gl-top-1">
          {{ seatsUsed }}
        </span>
        <span class="gl-font-lg">
          {{ $options.i18n.seatsUsedText }}
        </span>
        <gl-link
          :href="$options.helpLinks.seatsUsedLink"
          :aria-label="$options.i18n.seatsUsedHelpText"
          class="gl-ml-2 gl-relative"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </p>
      <p
        v-if="shouldRenderSeatsOwedBlock"
        class="gl-font-size-h-display gl-font-weight-bold gl-mb-0"
        data-testid="seats-owed-block"
        data-qa-selector="seats_owed"
      >
        <span class="gl-relative gl-top-1">
          {{ seatsOwed }}
        </span>
        <span class="gl-font-lg">
          {{ $options.i18n.seatsOwedText }}
        </span>
        <gl-link
          :href="$options.helpLinks.seatsOwedLink"
          :aria-label="$options.i18n.seatsOwedHelpText"
          class="gl-ml-2 gl-relative"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </p>
    </div>
    <gl-button
      v-if="purchaseButtonLink"
      :href="purchaseButtonLink"
      category="primary"
      target="_blank"
      variant="confirm"
      class="gl-ml-3 gl-align-self-start"
      data-testid="purchase-button"
      data-qa-selector="add_seats"
    >
      {{ $options.i18n.addSeatsText }}
    </gl-button>
  </div>
</template>
