<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import MergeRequestTableRow from './mr_table_row.vue';

export default {
  components: {
    GlCollapsibleListbox,
    MergeRequestTableRow,
    Pagination,
  },
  props: {
    mergeRequests: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    columnOptions: {
      type: Array,
      required: true,
    },
    metricType: {
      type: String,
      required: true,
    },
    metricLabel: {
      type: String,
      required: true,
    },
  },
  computed: {
    metricDropdownLabel() {
      return this.columnOptions.find((option) => option.key === this.metricType).label;
    },
    showPagination() {
      return this.pageInfo && this.pageInfo.total;
    },
    listBoxColumnOptions() {
      return this.columnOptions.map(({ key, label }) => ({
        value: key,
        text: label,
      }));
    },
  },
  methods: {
    onPageChange(page) {
      this.$emit('pageChange', page);
    },
  },
};
</script>

<template>
  <div class="mr-table">
    <div class="card">
      <div class="card-header border-bottom-0">
        <div role="row" class="gl-responsive-table-row table-row-header d-flex py-0">
          <div role="rowheader" class="table-section section-50 d-none d-md-flex">
            {{ __('Title') }}
          </div>
          <div role="rowheader" class="table-section section-50">
            <div class="d-flex">
              <span class="d-none d-md-flex metric-col">{{ __('Time to merge') }}</span>

              <gl-collapsible-listbox
                block
                fluid-width
                class="metric-col"
                toggle-class="dropdown-menu-toggle gl-w-full!"
                placement="right"
                is-check-centered
                :items="listBoxColumnOptions"
                :selected="metricType"
                :toggle-text="metricDropdownLabel"
                @select="$emit('columnMetricChange', $event)"
              />
            </div>
          </div>
        </div>
      </div>
      <div class="card-body py-0">
        <merge-request-table-row
          v-for="model in mergeRequests"
          :key="model.id"
          :merge-request="model"
          :metric-type="metricType"
          :metric-label="metricLabel"
        />
      </div>
    </div>

    <pagination
      v-if="showPagination"
      :change="onPageChange"
      :page-info="pageInfo"
      class="justify-content-center gl-mt-3"
    />
  </div>
</template>
