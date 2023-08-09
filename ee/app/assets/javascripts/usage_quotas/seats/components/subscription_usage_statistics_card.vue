<script>
import { GlButton, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';
import {
  addSeatsText,
  seatsInUseLink,
  seatsUsedLink,
  seatsOwedLink,
  seatsTooltipText,
  seatsTooltipTrialText,
  seatsUsedDescriptionText,
  seatsUsedText,
  seatsUsedHelpText,
  seatsOwedHelpText,
  seatsOwedText,
  subscriptionEndDateText,
  subscriptionStartDateText,
} from 'ee/usage_quotas/seats/constants';
import dateFormat from '~/lib/dateformat';

const subscriptionDateFormat = 'mmmm dd, yyyy';

export default {
  name: 'SubscriptionUsageStatisticsCard',
  components: {
    GlButton,
    GlIcon,
    GlLink,
    UsageStatistics,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    percentage: {
      type: Number,
      required: false,
      default: null,
    },
    usageValue: {
      type: String,
      required: false,
      default: null,
    },
    totalValue: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState([
      'activeTrial',
      'addSeatsHref',
      'hasLimitedFreePlan',
      'maxFreeNamespaceSeats',
      'maxSeatsUsed',
      'planCode',
      'seatsOwed',
      'subscriptionEndDate',
      'subscriptionStartDate',
    ]),
    formattedEndDate() {
      return dateFormat(this.subscriptionEndDate, subscriptionDateFormat);
    },
    formattedStartDate() {
      return dateFormat(this.subscriptionStartDate, subscriptionDateFormat);
    },
    seatsInUseDescriptionText() {
      if (!this.planCode) {
        return '';
      }
      return sprintf(this.$options.i18n.seatsUsedDescriptionText, {
        plan: capitalizeFirstCharacter(this.planCode),
      });
    },
    seatsInUseTooltipText() {
      if (!this.hasLimitedFreePlan) return null;
      if (this.activeTrial) return this.$options.i18n.seatsTooltipTrialText;

      return sprintf(this.$options.i18n.seatsTooltipText, {
        number: this.maxFreeNamespaceSeats,
      });
    },
  },
  helpLinks: {
    seatsInUseLink,
    seatsUsedLink,
    seatsOwedLink,
  },
  i18n: {
    addSeatsText,
    seatsTooltipText,
    seatsTooltipTrialText,
    seatsUsedDescriptionText,
    seatsUsedText,
    seatsUsedHelpText,
    seatsOwedHelpText,
    seatsOwedText,
    subscriptionEndDateText,
    subscriptionStartDateText,
  },
};
</script>
<template>
  <div class="gl-bg-white gl-border-1 gl-border-gray-100 gl-border-solid gl-p-6 gl-rounded-base">
    <usage-statistics :percentage="percentage" :usage-value="usageValue" :total-value="totalValue">
      <template #actions>
        <gl-button
          v-if="addSeatsHref"
          :href="addSeatsHref"
          category="primary"
          target="_blank"
          size="small"
          variant="default"
          data-testid="add-seats"
          data-qa-selector="add_seats"
        >
          {{ $options.i18n.addSeatsText }}
        </gl-button>
      </template>
      <template #description>
        <p
          v-if="seatsInUseDescriptionText"
          class="gl-font-weight-bold gl-mb-0"
          data-testid="seats-used-text"
        >
          {{ seatsInUseDescriptionText }}
          <gl-link
            v-if="$options.helpLinks.seatsInUseLink"
            class="gl-ml-2"
            target="_blank"
            :href="$options.helpLinks.seatsInUseLink"
            :title="seatsInUseTooltipText"
            data-testid="seats-used-link"
          >
            <gl-icon name="question-o" />
          </gl-link>
        </p>
      </template>
      <template #additional-info>
        <div class="gl-mt-5 gl-mb-3 gl-display-grid gl-grid-template-columns-2 gl-gap-3">
          <div class="gl-font-weight-bold" data-qa-selector="seats_used" data-testid="seats-used">
            <span class="gl-display-inline-block gl-mr-3">{{ maxSeatsUsed }}</span>
            <span>{{ $options.i18n.seatsUsedText }}</span>
            <gl-link
              :href="$options.helpLinks.seatsUsedLink"
              :aria-label="$options.i18n.seatsUsedHelpText"
              class="gl-ml-2 gl-relative"
            >
              <gl-icon name="question-o" />
            </gl-link>
          </div>
          <div class="gl-ml-auto gl-mr-0">
            <span class="gl-display-inline-block gl-mr-3 gl-font-weight-bold">{{
              $options.i18n.subscriptionStartDateText
            }}</span>
            <span data-testid="subscription-start-date">{{ formattedStartDate }}</span>
          </div>
          <div class="gl-font-weight-bold" data-qa-selector="seats_owed" data-testid="seats-owed">
            <span class="gl-display-inline-block gl-mr-3">{{ seatsOwed }}</span>
            <span>{{ $options.i18n.seatsOwedText }}</span>
            <gl-link
              :href="$options.helpLinks.seatsOwedLink"
              :aria-label="$options.i18n.seatsOwedHelpText"
              class="gl-ml-2 gl-relative"
            >
              <gl-icon name="question-o" />
            </gl-link>
          </div>
          <div class="gl-ml-auto gl-mr-0">
            <span class="gl-display-inline-block gl-mr-3 gl-font-weight-bold">{{
              $options.i18n.subscriptionEndDateText
            }}</span>
            <span data-testid="subscription-end-date">{{ formattedEndDate }}</span>
          </div>
        </div>
      </template>
    </usage-statistics>
  </div>
</template>
