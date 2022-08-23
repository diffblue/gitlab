<script>
import { GlBadge, GlPopover } from '@gitlab/ui';
import dateFormat from '~/lib/dateformat';
import {
  approximateDuration,
  differenceInMilliseconds,
} from '~/lib/utils/datetime/date_calculation_utility';
import { __, sprintf } from '~/locale';

export const LAST_UPDATED_TEXT = __('Last updated');
export const LAST_UPDATED_AGO_TEXT = __('Last updated %{time} ago');
export const NEXT_UPDATE_TEXT = __('Next update');
export const POPOVER_TITLE = __('Data refresh');

export const toYmdhs = (date) => dateFormat(date, 'yyyy-mm-dd HH:MM');

export default {
  name: 'ValueStreamAggregationStatus',
  components: { GlBadge, GlPopover },
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
  computed: {
    elapsedTimeParsedSeconds() {
      return differenceInMilliseconds(this.lastUpdated, this.currentTime) / 1000;
    },
    elapsedTimeText() {
      return sprintf(this.$options.i18n.LAST_UPDATED_AGO_TEXT, {
        time: approximateDuration(this.elapsedTimeParsedSeconds),
      });
    },
    lastUpdated() {
      return Date.parse(this.data.lastRunAt);
    },
    nextUpdate() {
      return Date.parse(this.data.nextRunAt);
    },
    formattedLastUpdated() {
      return toYmdhs(this.lastUpdated);
    },
    formattedNextUpdate() {
      return toYmdhs(this.nextUpdate);
    },
  },
  i18n: {
    LAST_UPDATED_AGO_TEXT,
    LAST_UPDATED_TEXT,
    NEXT_UPDATE_TEXT,
    POPOVER_TITLE,
  },
  currentTime: Date.now(),
};
</script>
<template>
  <div>
    <gl-badge id="vsa-data-refresh" variant="neutral" icon="information-o">{{
      elapsedTimeText
    }}</gl-badge>
    <gl-popover
      v-bind="$options.aggregationPopoverOptions"
      target="vsa-data-refresh"
      :title="$options.i18n.POPOVER_TITLE"
      :css-classes="['stage-item-popover']"
      data-testid="vsa-data-refresh-popover"
    >
      <div class="gl-px-4">
        <div
          data-testid="vsa-data-refresh-last"
          class="gl-display-flex gl-justify-content-space-between"
        >
          <div class="gl-pr-4 gl-pb-4">
            {{ $options.i18n.LAST_UPDATED_TEXT }}
          </div>
          <div class="gl-pb-4 gl-font-weight-bold">
            {{ formattedLastUpdated }}
          </div>
        </div>
        <div
          data-testid="vsa-data-refresh-next"
          class="gl-display-flex gl-justify-content-space-between"
        >
          <div class="gl-pr-4 gl-pb-4">
            {{ $options.i18n.NEXT_UPDATE_TEXT }}
          </div>
          <div class="gl-pb-4 gl-font-weight-bold">
            {{ formattedNextUpdate }}
          </div>
        </div>
      </div>
    </gl-popover>
  </div>
</template>
