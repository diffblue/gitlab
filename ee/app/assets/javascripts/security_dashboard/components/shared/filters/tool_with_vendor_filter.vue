<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider, GlTruncate } from '@gitlab/ui';
import { groupBy, mapKeys, mapValues, union, without, xor, get } from 'lodash';
import { s__ } from '~/locale';
import { REPORT_TYPES_WITH_MANUALLY_ADDED } from 'ee/security_dashboard/store/constants';
import { TYPENAME_VULNERABILITIES_SCANNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import FilterItem from './filter_item.vue';
import QuerystringSync from './querystring_sync.vue';
import DropdownButtonText from './dropdown_button_text.vue';
import { ALL_ID } from './constants';

export const VENDOR_GITLAB = 'GitLab';
export const NULL_SCANNER_ID = convertToGraphQLId(TYPENAME_VULNERABILITIES_SCANNER, 'null');
export const REPORT_TYPES = mapKeys(REPORT_TYPES_WITH_MANUALLY_ADDED, (_, key) =>
  key.toUpperCase(),
);

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlTruncate,
    FilterItem,
    QuerystringSync,
    DropdownButtonText,
  },
  inject: ['scanners'],
  data: () => ({
    selected: [],
  }),
  computed: {
    // Lookup object for vendors and report types. For more info see this comment:
    // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105823#note_1195179834
    vendors() {
      // First, group by the vendor. If there is no vendor, assume GitLab.
      const vendors = groupBy(this.scanners, ({ vendor }) => vendor.trim() || VENDOR_GITLAB);
      const lookup = mapValues(vendors, (vendor) => {
        // Then group each vendor's value by the report type.
        const reports = groupBy(vendor, 'report_type');
        // Then get only the scanner IDs for each report and convert them to GraphQL IDs.
        return mapValues(reports, (report) =>
          report.map(({ id }) => convertToGraphQLId(TYPENAME_VULNERABILITIES_SCANNER, id)),
        );
      });
      // Ensure that there's always a GitLab vendor and that it's always listed first.
      return { [VENDOR_GITLAB]: {}, ...lookup };
    },
    hasCustomVendor() {
      return Object.keys(this.vendors).length > 1;
    },
    selectedItemTexts() {
      return this.selected.length
        ? this.selected.map((id) => this.getReportName(id))
        : [this.$options.i18n.allItemsText];
    },
  },
  watch: {
    selected() {
      const scannerIds = this.selected.flatMap((id) => get(this.vendors, id)).filter(Boolean);
      const hasSelectedButNoScannerIds = this.selected.length && !scannerIds.length;
      // If scannerIds is an empty array, passing it to the vulnerabilities query is the same as not
      // applying the filter at all. However, if there are report types selected, this is incorrect.
      // As a workaround, we'll use a scanner ID that's guaranteed to return no results.
      this.$emit('filter-changed', {
        scannerId: hasSelectedButNoScannerIds ? [NULL_SCANNER_ID] : scannerIds,
      });
    },
  },
  methods: {
    getReportTypeIds(vendor) {
      // For the GitLab vendor, we show all report types even if they don't have scanner IDs. For
      // custom vendors, we only show report types that have scanner IDs.
      const reports = vendor === VENDOR_GITLAB ? REPORT_TYPES : this.vendors[vendor];

      return Object.keys(reports).map((id) => `${vendor}.${id}`);
    },
    getReportName(id) {
      // Split the ID to get the report type without the vendor name.
      return REPORT_TYPES[id.split('.')[1]];
    },
    deselectAll() {
      this.selected = [];
    },
    toggleAllIds(vendor) {
      const ids = this.getReportTypeIds(vendor);
      // If every ID for the vendor is already selected, deselect them. Otherwise, select them.
      this.selected = ids.every((id) => this.selected.includes(id))
        ? without(this.selected, ...ids)
        : union(this.selected, ids);
    },
    toggleSelected(id) {
      this.selected = xor(this.selected, [id]);
    },
  },
  i18n: {
    label: s__('SecurityReports|Tool'),
    allItemsText: s__('ciReport|All tools'),
  },
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="scanner" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-dropdown :header-text="$options.i18n.label" block toggle-class="gl-mb-0">
      <template #button-text>
        <dropdown-button-text :items="selectedItemTexts" :name="$options.i18n.label" />
      </template>

      <filter-item
        :is-checked="!selected.length"
        :text="$options.i18n.allItemsText"
        :data-testid="$options.ALL_ID"
        @click="deselectAll"
      />

      <template v-for="vendor in Object.keys(vendors)">
        <gl-dropdown-divider
          v-if="hasCustomVendor"
          :key="`${vendor}:divider`"
          :data-testid="`${vendor}:divider`"
        />

        <gl-dropdown-item
          v-if="hasCustomVendor"
          :key="`${vendor}:header`"
          :data-testid="`${vendor}:header`"
          @click.native.capture.stop="toggleAllIds(vendor)"
        >
          <gl-truncate class="gl-font-weight-bold" :text="vendor" />
        </gl-dropdown-item>

        <filter-item
          v-for="id in getReportTypeIds(vendor)"
          :key="id"
          :is-checked="selected.includes(id)"
          :text="getReportName(id)"
          :data-testid="id"
          @click="toggleSelected(id)"
        />
      </template>
    </gl-dropdown>
  </div>
</template>
