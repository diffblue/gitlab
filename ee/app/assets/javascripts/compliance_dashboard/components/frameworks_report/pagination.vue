<script>
import { GlKeysetPagination } from '@gitlab/ui';

import { s__ } from '~/locale';
import { NEXT, PREV } from '~/vue_shared/components/pagination/constants';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { setUrlParams } from '~/lib/utils/url_utility';

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
  computed: {
    previousLink() {
      return setUrlParams({ before: this.pageInfo.startCursor, after: null }, window.location.href);
    },
    nextLink() {
      return setUrlParams({ before: null, after: this.pageInfo.endCursor }, window.location.href);
    },
  },
  methods: {
    loadPrevPage(previousCursor) {
      this.$emit('prev', previousCursor);
    },
    loadNextPage(nextCursor) {
      this.$emit('next', nextCursor);
    },
    onPageSizeChange(size) {
      this.$emit('page-size-change', size);
    },
    onPaginationClick(event) {
      // this check here is to ensure the proper default behaviour when a user ctrl/cmd + clicks the link
      if (event.shiftKey || event.ctrlKey || event.altKey || event.metaKey) {
        return;
      }
      event.preventDefault();
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
  <div v-if="pageInfo" class="gl-md-display-flex gl-justify-content-space-between">
    <div class="gl-display-none gl-md-display-flex gl-flex-basis-0 gl-flex-grow-1"></div>
    <div
      class="gl-float-left gl-md-display-flex gl-flex-basis-0 gl-flex-grow-1 gl-justify-content-center"
    >
      <gl-keyset-pagination
        v-bind="pageInfo"
        :disabled="isLoading"
        :prev-text="$options.i18n.prev"
        :next-text="$options.i18n.next"
        :prev-button-link="previousLink"
        :next-button-link="nextLink"
        @prev="loadPrevPage"
        @next="loadNextPage"
        @click="onPaginationClick"
      />
    </div>
    <div
      class="gl-float-right gl-md-display-flex gl-flex-basis-0 gl-flex-grow-1 gl-justify-content-end"
    >
      <page-size-selector :value="perPage" @input="onPageSizeChange" />
    </div>
  </div>
</template>
