<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import {
  REPORT_TYPES_WITH_MANUALLY_ADDED,
  REPORT_TYPES_WITH_CLUSTER_IMAGE,
} from 'ee/security_dashboard/store/constants';
import { s__ } from '~/locale';
import { REPORT_TYPE_PRESETS } from 'ee/security_dashboard/components/shared/vulnerability_report/constants';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

export default {
  components: { QuerystringSync, GlCollapsibleListbox },
  inject: ['dashboardType'],
  data() {
    return {
      selected: [],
    };
  },
  computed: {
    items() {
      const allOption = { value: ALL_ID, text: this.$options.i18n.allItemsText };
      const reportTypes =
        this.dashboardType === 'pipeline'
          ? REPORT_TYPES_WITH_CLUSTER_IMAGE
          : REPORT_TYPES_WITH_MANUALLY_ADDED;

      // For backwards compatibility with existing bookmarks, the ID needs to be capitalized.
      const options = Object.entries(reportTypes).map(([id, text]) => ({
        value: id.toUpperCase(),
        text,
      }));

      return [allOption, ...options];
    },
    selectedIds() {
      // This prevents the querystring-sync component from redirecting the page to /?scanner_id=ALL.
      return this.selected.length ? this.selected : [ALL_ID];
    },
    toggleText() {
      return getSelectedOptionsText({
        options: this.items,
        selected: this.selectedIds,
        placeholder: this.$options.i18n.allItemsText,
      });
    },
  },
  watch: {
    selected() {
      this.$emit('filter-changed', {
        // Filter out cluster image scanning results if there's no selected report types.
        reportType: this.selected.length ? this.selected : REPORT_TYPE_PRESETS.DEVELOPMENT,
      });
    },
  },
  methods: {
    updateSelected(selected) {
      if (selected.at(-1) === ALL_ID) {
        this.selected = [];
      } else {
        this.selected = selected.filter((s) => s !== ALL_ID);
      }
    },
  },
  i18n: {
    label: s__('SecurityReports|Tool'),
    allItemsText: s__('SecurityReports|All tools'),
  },
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="reportType" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-collapsible-listbox
      :items="items"
      :header-text="$options.i18n.label"
      :toggle-text="toggleText"
      :selected="selectedIds"
      multiple
      block
      data-testid="filter-tool-dropdown"
      @select="updateSelected"
    />
  </div>
</template>
