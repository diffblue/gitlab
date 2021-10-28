<script>
import BoardFilteredSearchCe from '~/boards/components/board_filtered_search.vue';

export default {
  components: { BoardFilteredSearchCe },
  props: {
    tokens: {
      required: true,
      type: Array,
    },
  },
};
</script>

<template>
  <board-filtered-search-ce v-bind="{ ...$props, ...$attrs }" />
</template>
