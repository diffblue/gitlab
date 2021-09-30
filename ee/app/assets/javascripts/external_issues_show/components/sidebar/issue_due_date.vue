<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { dateInWords, getDayDifference, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
  props: {
    dueDate: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    dueDateInWords() {
      const date = parsePikadayDate(this.dueDate);

      return dateInWords(date, true);
    },
    formattedDueDate() {
      const today = new Date();
      const date = parsePikadayDate(this.dueDate);
      const isPastDue = getDayDifference(today, date) < 0;

      let formattedDate = this.dueDateInWords;

      if (isPastDue) {
        formattedDate += ` (${__('Past due')})`;
      }

      return formattedDate;
    },
    dueDateTooltipProps() {
      return {
        boundary: 'viewport',
        placement: 'left',
        title: this.dueDate
          ? `${this.$options.i18n.dueDateTitle}<br>${this.formattedDueDate}`
          : this.$options.i18n.dueDateTitle,
      };
    },
  },
  i18n: {
    dueDateTitle: __('Due date'),
    none: __('None'),
  },
};
</script>

<template>
  <div class="block">
    <div
      v-gl-tooltip.html="dueDateTooltipProps"
      class="sidebar-collapsed-icon"
      data-testid="due-date-collapsed"
    >
      <gl-icon name="calendar" />
      <span v-if="dueDate">{{ dueDateInWords }}</span>
      <span v-else>{{ $options.i18n.none }}</span>
    </div>

    <div class="hide-collapsed">
      <div class="title">{{ $options.i18n.dueDateTitle }}</div>
      <div class="value" data-testid="due-date-value">
        <strong v-if="dueDate">{{ formattedDueDate }}</strong>
        <span v-else class="no-value">{{ $options.i18n.none }}</span>
      </div>
    </div>
  </div>
</template>
