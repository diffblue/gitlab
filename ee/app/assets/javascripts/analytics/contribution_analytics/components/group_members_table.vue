<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { TABLE_COLUMNS } from '../constants';

import GroupMembers from '../group_members';
import TableBody from './table_body.vue';
import TableHeader from './table_header.vue';

export default {
  columns: TABLE_COLUMNS,
  components: {
    TableHeader,
    TableBody,
    GlLoadingIcon,
  },
  inject: ['memberContributionsPath'],
  data() {
    return { groupMembers: new GroupMembers(this.memberContributionsPath) };
  },
  computed: {
    isLoading() {
      return this.groupMembers.isLoading;
    },
    members() {
      return this.groupMembers.members;
    },
    sortOrders() {
      return this.groupMembers.sortOrders;
    },
  },
  mounted() {
    this.groupMembers.fetchContributedMembers();
  },
  methods: {
    handleColumnClick(columnName) {
      this.groupMembers.sortMembers(columnName);
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
