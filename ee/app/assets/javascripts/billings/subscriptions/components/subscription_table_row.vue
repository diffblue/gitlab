<script>
import { GlIcon, GlButton } from '@gitlab/ui';
import { TABLE_TYPE_DEFAULT } from 'ee/billings/constants';
import { dateInWords } from '~/lib/utils/datetime_utility';
import Popover from '~/vue_shared/components/help_popover.vue';
import { convertToSnakeCase } from '~/lib/utils/text_utility';

export default {
  name: 'SubscriptionTableRow',
  components: {
    GlButton,
    GlIcon,
    Popover,
  },
  inject: {
    billableSeatsHref: {
      default: '',
    },
    seatsLastUpdated: {
      default: '',
    },
  },
  props: {
    header: {
      type: Object,
      required: true,
    },
    columns: {
      type: Array,
      required: true,
    },
    last: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFreePlan: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    rowClasses() {
      return !this.last ? 'gl-border-b-gray-100 gl-border-b-1 gl-border-b-solid' : null;
    },
  },
  methods: {
    getPopoverOptions(col) {
      const defaults = {
        placement: 'bottom',
      };
      return { ...defaults, ...col.popover };
    },
    getDisplayValue(col) {
      if (col.isDate && col.value) {
        const [year, month, day] = col.value.split('-');

        // create UTC date (prevent date from being converted to local timezone)
        return dateInWords(new Date(year, month - 1, day));
      }

      // let's display '-' instead of 0 for the 'Free' plan
      if (this.isFreePlan && col.value === 0) {
        return ' - ';
      }

      return typeof col.value !== 'undefined' && col.value !== null ? col.value : ' - ';
    },
    isSeatsUsageButtonShown(col) {
      return this.billableSeatsHref && col.id === 'seatsInUse';
    },
    qaSelectorValue(col) {
      return convertToSnakeCase(col?.label ?? '');
    },
  },
  TABLE_TYPE_DEFAULT,
};
</script>

<template>
  <div
    :class="rowClasses"
    class="gl-display-flex gl-flex-grow-1 gl-flex-direction-column gl-lg-flex-direction-row"
  >
    <div class="grid-cell header-cell" data-testid="header-cell">
      <span class="icon-wrapper">
        <gl-icon v-if="header.icon" class="gl-mr-3" :name="header.icon" />
        {{ header.title }}
      </span>
    </div>
    <template v-for="(col, i) in columns">
      <div
        :key="`subscription-col-${i}`"
        class="grid-cell gl-display-flex gl-flex-direction-column gl-align-items-baseline"
        data-testid="content-cell"
        :class="[col.hideContent ? 'no-value' : '']"
      >
        <span>
          <span data-testid="property-label" class="property-label">{{ col.label }}</span>
          <popover v-if="col.popover" :options="getPopoverOptions(col)" />
        </span>
        <p
          data-testid="property-value"
          class="property-value gl-mt-2 gl-mb-0 gl-flex-grow-1"
          :data-qa-selector="qaSelectorValue(col)"
          :class="[col.colClass ? col.colClass : '']"
        >
          {{ getDisplayValue(col) }}
        </p>
        <gl-button
          v-if="isSeatsUsageButtonShown(col)"
          :href="billableSeatsHref"
          data-testid="seats-usage-button"
          data-qa-selector="see_seats_usage"
          size="small"
          class="gl-mt-3"
          >{{ s__('SubscriptionTable|See usage') }}</gl-button
        >
        <p
          v-if="seatsLastUpdated && col.type === $options.TABLE_TYPE_DEFAULT"
          class="gl-mb-0 gl-pt-3 gl-font-sm gl-text-secondary"
          data-testid="seats-last-updated"
        >
          <template v-if="col.id === 'seatsInSubscription'">
            {{ s__('SubscriptionTable|Up to date') }}
          </template>
          <template v-else>
            {{
              sprintf(s__('SubscriptionTable|Last updated at %{seatsLastUpdated} UTC'), {
                seatsLastUpdated,
              })
            }}
          </template>
        </p>
      </div>
    </template>
  </div>
</template>
