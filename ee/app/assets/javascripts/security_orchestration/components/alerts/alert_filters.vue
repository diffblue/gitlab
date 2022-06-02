<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlFormGroup,
  GlIcon,
  GlSearchBoxByType,
  GlTruncate,
} from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import { ALL, DEBOUNCE, STATUSES } from './constants';

export default {
  ALL,
  DEBOUNCE,
  DEFAULT_DISMISSED_FILTER: true,
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlFormGroup,
    GlIcon,
    GlSearchBoxByType,
    GlTruncate,
  },
  props: {
    filters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      showMinimumSearchQueryMessage: false,
    };
  },
  i18n: {
    STATUSES,
    HIDE_DISMISSED_TITLE: s__('ThreatMonitoring|Hide dismissed alerts'),
    POLICY_NAME_FILTER_PLACEHOLDER: s__('NetworkPolicy|Search by policy name'),
    POLICY_NAME_FILTER_TITLE: s__('NetworkPolicy|Policy'),
    POLICY_STATUS_FILTER_TITLE: s__('NetworkPolicy|Status'),
  },
  computed: {
    extraOptionCount() {
      const numOfStatuses = this.filters.statuses?.length || 0;
      return numOfStatuses > 0 ? numOfStatuses - 1 : 0;
    },
    firstSelectedOption() {
      const firstOption = this.filters.statuses?.length ? this.filters.statuses[0] : undefined;
      return this.$options.i18n.STATUSES[firstOption] || this.$options.ALL.value;
    },
    extraOptionText() {
      return sprintf(__('+%{extra} more'), { extra: this.extraOptionCount });
    },
  },
  methods: {
    handleFilterChange(newFilters) {
      this.$emit('filter-change', { ...this.filters, ...newFilters });
    },
    handleNameFilter(searchTerm) {
      const newFilters = { searchTerm };
      this.handleFilterChange(newFilters);
    },
    handleStatusFilter(status) {
      let newFilters;

      if (status === this.$options.ALL.key) {
        newFilters = { statuses: [] };
      } else {
        newFilters = this.isChecked(status)
          ? { statuses: [...this.filters.statuses.filter((s) => s !== status)] }
          : { statuses: [...this.filters.statuses, status] };
      }

      // If all statuses are selected, select the 'All' option
      if (newFilters.statuses.length === Object.entries(STATUSES).length) {
        newFilters = { statuses: [] };
      }

      this.handleFilterChange(newFilters);
    },
    isChecked(status) {
      if (status === this.$options.ALL.key) {
        return !this.filters.statuses?.length;
      }
      return this.filters.statuses?.includes(status);
    },
  },
};
</script>

<template>
  <div class="gl-p-4 gl-bg-gray-10 gl-display-flex gl-align-items-center">
    <gl-form-group :label="$options.i18n.POLICY_NAME_FILTER_TITLE" label-size="sm" class="gl-mb-0">
      <gl-search-box-by-type
        :debounce="$options.DEBOUNCE"
        :placeholder="$options.i18n.POLICY_NAME_FILTER_PLACEHOLDER"
        @input="handleNameFilter"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.POLICY_STATUS_FILTER_TITLE"
      label-size="sm"
      class="gl-mb-0 col-sm-6 col-md-4 col-lg-2"
      data-testid="policy-alert-status-filter"
    >
      <gl-dropdown toggle-class="gl-inset-border-1-gray-400!" class="gl-w-full">
        <template #button-content>
          <gl-truncate :text="firstSelectedOption" class="gl-min-w-0 gl-mr-2" />
          <span v-if="extraOptionCount > 0" class="gl-mr-2">
            {{ extraOptionText }}
          </span>
          <gl-icon name="chevron-down" class="gl-flex-shrink-0 gl-ml-auto" />
        </template>

        <gl-dropdown-item
          key="All"
          data-testid="ALL"
          :is-checked="isChecked($options.ALL.key)"
          is-check-item
          @click="handleStatusFilter($options.ALL.key)"
        >
          {{ $options.ALL.value }}
        </gl-dropdown-item>
        <gl-dropdown-divider />
        <template v-for="[status, translated] in Object.entries($options.i18n.STATUSES)">
          <gl-dropdown-item
            :key="status"
            :data-testid="status"
            :is-checked="isChecked(status)"
            is-check-item
            @click="handleStatusFilter(status)"
          >
            {{ translated }}
          </gl-dropdown-item>
        </template>
      </gl-dropdown>
    </gl-form-group>
  </div>
</template>
