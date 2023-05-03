<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import getProjectDataTransferEgress from '../graphql/queries/get_project_data_transfer_egress.query.graphql';
import UsageByType from './usage_by_type.vue';

export default {
  i18n: {
    ERROR_MESSAGE: s__(
      'UsageQuotas|An error occurred loading the transfer data. Please refresh the page to try again.',
    ),
  },
  components: { GlAlert, UsageByType },
  inject: ['fullPath'],
  data() {
    return {
      projectDataTransferEgress: {},
      hasError: false,
    };
  },
  apollo: {
    projectDataTransferEgress: {
      query: getProjectDataTransferEgress,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.project;
      },
      error() {
        this.hasError = true;
      },
    },
  },
  computed: {
    egressNodes() {
      return this.projectDataTransferEgress?.dataTransfer?.egressNodes?.nodes || [];
    },
    isLoading() {
      return this.$apollo.queries.projectDataTransferEgress.loading;
    },
  },
  methods: {
    onAlertDismiss() {
      this.hasError = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="hasError" class="gl-mt-5" variant="danger" @dismiss="onAlertDismiss">{{
      $options.i18n.ERROR_MESSAGE
    }}</gl-alert>
    <usage-by-type :egress-nodes="egressNodes" :loading="isLoading" />
  </div>
</template>
