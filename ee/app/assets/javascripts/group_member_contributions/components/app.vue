<script>
import { GlLoadingIcon } from '@gitlab/ui';
import COLUMNS from '../constants';

import TableBody from './table_body.vue';
import TableHeader from './table_header.vue';

export default {
  columns: COLUMNS,
  components: {
    TableHeader,
    TableBody,
    GlLoadingIcon,
  },
  props: {
    store: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isLoading() {
      return this.store.isLoading;
    },
    members() {
      return this.store.members;
    },
    sortOrders() {
      return this.store.sortOrders;
    },
  },
  methods: {
    handleColumnClick(columnName) {
      this.store.sortMembers(columnName);
    },
  },
};
</script>

<template>
  <div class="group-member-contributions-container">
    <h3>{{ __('Contributions per group member') }}</h3>
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading contribution stats for group members')"
      size="lg"
      class="loading-animation prepend-top-20 append-bottom-20"
    />
    <table v-else class="table gl-sortable">
      <table-header
        :columns="$options.columns"
        :sort-orders="sortOrders"
        @onColumnClick="handleColumnClick"
      />
      <table-body :rows="members" />
    </table>
  </div>
</template>
