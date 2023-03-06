<script>
import { GlKeysetPagination } from '@gitlab/ui';

import { s__ } from '~/locale';
import { NEXT, PREV } from '~/vue_shared/components/pagination/constants';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';

export default {
  components: {
    GlKeysetPagination,
    PageSizeSelector,
  },
  props: {
    pageInfo: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    perPage: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      pageSizes: [20, 50, 100],
    };
  },
  methods: {
    loadPrevPage(cursor) {
      this.$emit('prev', cursor);
    },
    loadNextPage(cursor) {
      this.$emit('next', cursor);
    },
    onPageSizeChange(size) {
      this.$emit('page-size-change', size);
    },
  },
  i18n: {
    queryError: s__(
      'ComplianceReport|Retrieving the compliance framework report failed. Refresh the page and try again.',
    ),
    prev: PREV,
    next: NEXT,
  },
};
</script>

<template>
  <div class="gl-md-display-flex gl-justify-content-space-between">
    <div class="gl-display-none gl-md-display-flex gl-flex-basis-0 gl-flex-grow-1"></div>
    <div
      class="gl-float-left gl-md-display-flex gl-flex-basis-0 gl-flex-grow-1 gl-justify-content-center"
    >
      <gl-keyset-pagination
        v-bind="pageInfo"
        :disabled="isLoading"
        :prev-text="$options.i18n.prev"
        :next-text="$options.i18n.next"
        @prev="loadPrevPage"
        @next="loadNextPage"
      />
    </div>
    <div
      class="gl-float-right gl-md-display-flex gl-flex-basis-0 gl-flex-grow-1 gl-justify-content-end"
    >
      <page-size-selector :value="perPage" @input="onPageSizeChange" />
    </div>
  </div>
</template>
