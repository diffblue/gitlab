<script>
import { __ } from '~/locale';
import { ancestorsQueries } from '../../queries/constants';
import Ancestors from './ancestors_tree.vue';

export default {
  i18n: {
    fetchingError: __('An error occurred while fetching ancestors'),
  },
  components: {
    Ancestors,
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      ancestors: [],
    };
  },
  apollo: {
    ancestors: {
      query() {
        return ancestorsQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update(data) {
        return data.workspace?.issuable?.ancestors.nodes || [];
      },
      error(error) {
        this.$emit('fetch-error', {
          message: this.$options.i18n.fetchingError,
          error,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.ancestors.loading;
    },
  },
};
</script>

<template>
  <ancestors :is-fetching="isLoading" :ancestors="ancestors" class="block ancestors" />
</template>
