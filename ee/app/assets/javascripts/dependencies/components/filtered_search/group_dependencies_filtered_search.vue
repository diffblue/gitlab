<script>
import { GlFilteredSearch } from '@gitlab/ui';

export default {
  components: {
    GlFilteredSearch,
  },
  data() {
    return {
      value: [],
    };
  },
  computed: {
    tokens() {
      // adding filter tokens will be addressed in separate issues/MRs:
      // * https://gitlab.com/gitlab-org/gitlab/-/issues/422356
      // * https://gitlab.com/gitlab-org/gitlab/-/issues/422355
      return [];
    },
  },
  methods: {
    filterDependencies() {
      // connecting the filter with the parent component, which is responsible for
      // API calls, will be addressed in a separate MR
    },
  },
};
</script>

<template>
  <gl-filtered-search
    v-model="value"
    :placeholder="__('Search or filter dependencies...')"
    :available-tokens="tokens"
    @submit="filterDependencies"
  />
</template>
