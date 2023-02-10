<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import contributionsQuery from '../graphql/contributions.query.graphql';

export default {
  name: 'ContributionAnalyticsApp',
  components: {
    GlLoadingIcon,
    GlAlert,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    startDate: {
      type: String,
      required: true,
    },
    endDate: {
      type: String,
      required: true,
    },
  },
  i18n: {
    loading: s__('ContributionAnalytics|Loading contribution stats for group members'),
    error: s__('ContributionAnalytics|Failed to load the contribution stats'),
  },
  data() {
    return {
      contributions: [],
      loadError: false,
    };
  },
  apollo: {
    contributions: {
      query: contributionsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          startDate: this.startDate,
          endDate: this.endDate,
        };
      },
      update(data) {
        return data.group?.contributions.nodes || [];
      },
      error() {
        this.loadError = true;
      },
    },
  },
  computed: {
    loading() {
      return Boolean(this.$apollo.queries.contributions?.loading);
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="loading" :label="$options.i18n.loading" size="lg" />

    <gl-alert v-else-if="loadError" variant="danger" :dismissible="false">
      {{ $options.i18n.error }}
    </gl-alert>
  </div>
</template>
