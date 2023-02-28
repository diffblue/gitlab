<script>
import { mapActions, mapState } from 'vuex';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import DependenciesTable from './dependencies_table.vue';

export default {
  name: 'PaginatedDependenciesTable',
  components: {
    DependenciesTable,
    Pagination,
  },
  props: {
    namespace: {
      type: String,
      required: true,
      validator: (value) =>
        Object.values(DEPENDENCY_LIST_TYPES).some(({ namespace }) => value === namespace),
    },
  },
  computed: {
    ...mapState({
      module(state) {
        return state[this.namespace];
      },
      shouldShowPagination() {
        const { isLoading, errorLoading, pageInfo } = this.module;
        return Boolean(!isLoading && !errorLoading && pageInfo && pageInfo.total);
      },
    }),
  },
  methods: {
    ...mapActions({
      fetchPage(dispatch, page) {
        return dispatch(`${this.namespace}/fetchDependencies`, { page });
      },
    }),
  },
};
</script>

<template>
  <div>
    <dependencies-table :dependencies="module.dependencies" :is-loading="module.isLoading" />

    <pagination
      v-if="shouldShowPagination"
      :change="fetchPage"
      :page-info="module.pageInfo"
      align="center"
    />
  </div>
</template>
