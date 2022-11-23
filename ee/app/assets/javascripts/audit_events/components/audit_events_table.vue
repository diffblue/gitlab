<script>
import { GlPagination, GlTable } from '@gitlab/ui';

import { getParameterValues, setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import UserDate from '~/vue_shared/components/user_date.vue';
import { LONG_DATE_FORMAT_WITH_TZ } from '~/vue_shared/constants';

import HtmlTableCell from './table_cells/html_table_cell.vue';
import UrlTableCell from './table_cells/url_table_cell.vue';

const TABLE_HEADER_CLASSES = 'bg-transparent border-bottom p-3';

export default {
  components: {
    HtmlTableCell,
    GlTable,
    GlPagination,
    UrlTableCell,
    UserDate,
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
  },
  data() {
    return {
      page: parseInt(getParameterValues('page')[0], 10) || 1,
    };
  },
  computed: {
    displayPagination() {
      return this.events.length > 0;
    },
    prevPage() {
      return this.page > 1 ? this.page - 1 : null;
    },
    nextPage() {
      return !this.isLastPage ? this.page + 1 : null;
    },
  },
  methods: {
    generateLink(page) {
      return setUrlParams({ page });
    },
  },
  fields: [
    {
      key: 'author',
      label: s__('AuditLogs|Author'),
      thClass: TABLE_HEADER_CLASSES,
    },
    {
      key: 'object',
      label: s__('AuditLogs|Object'),
      thClass: TABLE_HEADER_CLASSES,
    },
    {
      key: 'action',
      label: s__('AuditLogs|Action'),
      thClass: TABLE_HEADER_CLASSES,
    },
    {
      key: 'target',
      label: s__('AuditLogs|Target'),
      thClass: TABLE_HEADER_CLASSES,
    },
    {
      key: 'ip_address',
      label: s__('AuditLogs|IP Address'),
      thClass: TABLE_HEADER_CLASSES,
    },
    {
      key: 'date',
      label: s__('AuditLogs|Date'),
      thClass: TABLE_HEADER_CLASSES,
    },
  ],
  dateTimeFormat: LONG_DATE_FORMAT_WITH_TZ,
};
</script>

<template>
  <div class="audit-log-table" data-qa-selector="audit_log_table">
    <gl-table class="gl-mt-5" :fields="$options.fields" :items="events" show-empty stacked="md">
      <template #cell(author)="{ value: { url, name } }">
        <url-table-cell :url="url" :name="name" />
      </template>
      <template #cell(object)="{ value: { url, name } }">
        <url-table-cell :url="url" :name="name" />
      </template>
      <template #cell(action)="{ value }">
        <html-table-cell :html="value" />
      </template>
      <template #cell(date)="{ value }">
        <user-date :date="value" :date-format="$options.dateTimeFormat" />
      </template>
    </gl-table>
    <gl-pagination
      v-if="displayPagination"
      v-model="page"
      :prev-page="prevPage"
      :next-page="nextPage"
      :link-gen="generateLink"
      align="center"
      class="w-100"
    />
  </div>
</template>
