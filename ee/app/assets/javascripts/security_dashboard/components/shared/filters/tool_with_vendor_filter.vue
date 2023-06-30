<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { groupBy, mapKeys, mapValues, get } from 'lodash';
import { s__ } from '~/locale';
import { REPORT_TYPES_WITH_MANUALLY_ADDED } from 'ee/security_dashboard/store/constants';
import { TYPENAME_VULNERABILITIES_SCANNER } from '~/graphql_shared/constants';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { REPORT_TYPE_PRESETS } from 'ee/security_dashboard/components/shared/vulnerability_report/constants';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

export const VENDOR_GITLAB = 'GitLab';
export const NULL_SCANNER_ID = convertToGraphQLId(TYPENAME_VULNERABILITIES_SCANNER, 'null');
export const REPORT_TYPES = mapKeys(REPORT_TYPES_WITH_MANUALLY_ADDED, (_, key) =>
  key.toUpperCase(),
);

export default {
  components: {
    QuerystringSync,
    GlCollapsibleListbox,
  },
  inject: ['scanners'],
  data() {
    return {
      selected: [],
    };
  },
  computed: {
    selectedIds() {
      // This prevents the querystring-sync component from redirecting the page to /?scanner_id=ALL.
      return this.selected.length ? this.selected : [ALL_ID];
    },

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

    toggleText() {
      return getSelectedOptionsText({
        options: this.hasCustomVendor ? this.items.flatMap(({ options }) => options) : this.items,
        selected: this.selectedIds,
        placeholder: this.$options.i18n.allItemsText,
      });
    },

    items() {
      const allOption = { value: ALL_ID, text: this.$options.i18n.allItemsText };

      if (this.hasCustomVendor) {
        return [
          {
            text: '',
            textSrOnly: true,
            options: [allOption],
          },
          ...Object.keys(this.vendors).map((vendor) => {
            return {
              text: vendor,
              options: this.getVendorOptions(vendor),
            };
          }),
        ];
      }

      return [allOption, ...this.getVendorOptions(VENDOR_GITLAB)];
    },
  },
  watch: {
    selected() {
      // We will either use scannerId or reportType, but not both. If we set one, we need to clear out the other.
      const filterData = { scannerId: undefined, reportType: undefined };
      const { selected } = this;

      if (this.hasCustomVendor) {
        // Filter by scanner ID if there are selected items. If the selected items don't have any scanner IDs, use a
        // fake ID that's guaranteed to return no results. This is to work around a backend issue where filtering using
        // an empty array will treat it as if the filter is not applied.
        if (selected.length) {
          const scannerIds = selected.flatMap((id) => get(this.vendors, id, []));

          filterData.scannerId = scannerIds.length ? scannerIds : [NULL_SCANNER_ID];
        }
        // Otherwise, use the preset that removes cluster image scanning results.
        else {
          filterData.reportType = REPORT_TYPE_PRESETS.DEVELOPMENT;
        }
      }
      // No custom vendors, filter by the selected report types, or if nothing's selected, the preset that removes
      // cluster image scanning results.
      else {
        const reportTypes = selected.map((id) => id.split('.')[1]);
        filterData.reportType = reportTypes.length ? reportTypes : REPORT_TYPE_PRESETS.DEVELOPMENT;
      }

      this.$emit('filter-changed', filterData);
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
      const reportTypeWithoutVendorName = id.split('.').pop();
      return REPORT_TYPES[reportTypeWithoutVendorName];
    },

    getVendorOptions(vendor) {
      return this.getReportTypeIds(vendor).map((value) => ({
        value,
        text: this.getReportName(value),
      }));
    },

    updateSelected(selected) {
      if (selected.at(-1) === ALL_ID || !selected.length) {
        this.selected = [];
      } else if (selected.length > 0) {
        this.selected = selected.filter((s) => s !== ALL_ID);
      }
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
    <gl-collapsible-listbox
      :items="items"
      :header-text="$options.i18n.label"
      :toggle-text="toggleText"
      :selected="selectedIds"
      multiple
      block
      @select="updateSelected"
    />
  </div>
</template>
