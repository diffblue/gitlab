<script>
import { mapActions, mapState } from 'vuex';
import Pagination from '~/vue_shared/components/pagination_links.vue';
import { LICENSE_LIST } from '../store/constants';
import LicensesTable from './licenses_table.vue';

export default {
  name: 'DetectedLicensesTable',
  components: {
    LicensesTable,
    Pagination,
  },
  computed: {
    ...mapState(LICENSE_LIST, ['licenses', 'isLoading', 'initialized', 'pageInfo']),
    shouldShowPagination() {
      const { initialized, pageInfo } = this;
      return Boolean(initialized && pageInfo && pageInfo.total);
    },
  },
  methods: {
    ...mapActions(LICENSE_LIST, ['fetchLicenses']),
    fetchPage(page) {
      return this.fetchLicenses({ page });
    },
  },
};
</script>

<template>
  <div>
    <licenses-table :licenses="licenses" :is-loading="isLoading" />

    <pagination
      v-if="shouldShowPagination"
      :change="fetchPage"
      :page-info="pageInfo"
      align="center"
    />
  </div>
</template>
