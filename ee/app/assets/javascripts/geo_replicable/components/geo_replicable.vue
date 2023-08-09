<script>
import { GlPagination } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { PREV, NEXT } from '../constants';
import GeoReplicableItem from './geo_replicable_item.vue';

export default {
  name: 'GeoReplicable',
  components: {
    GlPagination,
    GeoReplicableItem,
  },
  computed: {
    ...mapState(['replicableItems', 'paginationData', 'useGraphQl']),
    page: {
      get() {
        return this.paginationData.page;
      },
      set(newVal) {
        let action;
        if (this.useGraphQl) {
          action = this.page > newVal ? PREV : NEXT;
        }

        this.setPage(newVal);
        this.fetchReplicableItems(action);
      },
    },
    paginationProps() {
      if (!this.useGraphQl) {
        return {
          perPage: this.paginationData.perPage,
          totalItems: this.paginationData.total,
        };
      }

      return {
        prevPage: this.paginationData.hasPreviousPage ? this.page - 1 : null,
        nextPage: this.paginationData.hasNextPage ? this.page + 1 : null,
      };
    },
  },
  methods: {
    ...mapActions(['setPage', 'fetchReplicableItems']),
    buildName(item) {
      return item.name ? item.name : item.id;
    },
    buildRegistryId(item) {
      return this.useGraphQl ? item.id : item.projectId;
    },
  },
};
</script>

<template>
  <section>
    <geo-replicable-item
      v-for="item in replicableItems"
      :key="buildRegistryId(item)"
      :name="buildName(item)"
      :registry-id="buildRegistryId(item)"
      :sync-status="item.state.toLowerCase()"
      :last-synced="item.lastSyncedAt"
      :last-verified="item.verifiedAt"
    />
    <gl-pagination v-model="page" v-bind="paginationProps" align="center" class="gl-mt-6" />
  </section>
</template>
