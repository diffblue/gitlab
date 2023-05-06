<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { WORKSPACES_LIST_PAGE_SIZE } from '../../constants';

export default {
  components: {
    GlKeysetPagination,
  },
  props: {
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  methods: {
    nextPage() {
      this.$emit('input', {
        after: this.pageInfo.endCursor,
        first: WORKSPACES_LIST_PAGE_SIZE,
      });
    },
    previousPage() {
      this.$emit('input', {
        before: this.pageInfo.startCursor,
        first: WORKSPACES_LIST_PAGE_SIZE,
      });
    },
  },
};
</script>
<template>
  <div
    v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage"
    class="gl-display-flex gl-justify-content-center gl-mt-3"
  >
    <gl-keyset-pagination
      :has-next-page="pageInfo.hasNextPage"
      :has-previous-page="pageInfo.hasPreviousPage"
      @prev="previousPage"
      @next="nextPage"
    />
  </div>
</template>
