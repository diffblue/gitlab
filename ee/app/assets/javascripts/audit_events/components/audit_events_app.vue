<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import AuditEventsExportButton from './audit_events_export_button.vue';
import AuditEventsFilter from './audit_events_filter.vue';
import AuditEventsTable from './audit_events_table.vue';
import DateRangeField from './date_range_field.vue';
import SortingField from './sorting_field.vue';

export default {
  components: {
    AuditEventsFilter,
    DateRangeField,
    SortingField,
    AuditEventsTable,
    AuditEventsExportButton,
  },
  props: {
    events: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLastPage: {
      type: Boolean,
      required: false,
      default: false,
    },
    filterTokenOptions: {
      type: Array,
      required: true,
    },
    exportUrl: {
      type: String,
      required: false,
      default: '',
    },
    showFilter: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    ...mapState(['filterValue', 'startDate', 'endDate', 'sortBy']),
    ...mapGetters(['buildExportHref']),
    exportHref() {
      return this.buildExportHref(this.exportUrl);
    },
    hasExportUrl() {
      return this.exportUrl.length;
    },
  },
  methods: {
    ...mapActions(['setDateRange', 'setFilterValue', 'setSortBy', 'searchForAuditEvents']),
  },
};
</script>

<template>
  <div>
    <header>
      <div class="gl-my-5 gl-display-flex gl-flex-direction-row gl-justify-content-end">
        <audit-events-export-button v-if="hasExportUrl" :export-href="exportHref" />
      </div>
    </header>
    <div class="row-content-block second-block gl-pb-0">
      <div class="gl-display-flex gl-justify-content-space-between gl-flex-wrap">
        <div v-if="showFilter" class="gl-mb-5 gl-w-full">
          <audit-events-filter
            :filter-token-options="filterTokenOptions"
            :value="filterValue"
            @selected="setFilterValue"
            @submit="searchForAuditEvents"
          />
        </div>
        <div class="gl-display-flex gl-flex-wrap gl-w-full">
          <div
            class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-justify-content-space-between gl-px-0 gl-w-full"
          >
            <date-range-field
              :start-date="startDate"
              :end-date="endDate"
              @selected="setDateRange"
            />
            <sorting-field :sort-by="sortBy" @selected="setSortBy" />
          </div>
        </div>
      </div>
    </div>
    <audit-events-table :events="events" :is-last-page="isLastPage" />
  </div>
</template>
