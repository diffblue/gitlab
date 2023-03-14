<script>
import { GlAlert } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { numberToHumanSizeSplit } from '~/lib/utils/number_utils';
import { USAGE_BY_MONTH_HEADER, USAGE_BY_PROJECT_HEADER } from '../../constants';
import getGroupDataTransferEgress from '../graphql/queries/get_group_data_transfer_egress.query.graphql';
import StatisticsCard from '../../components/statistics_card.vue';

export default {
  i18n: {
    USAGE_BY_MONTH_HEADER,
    USAGE_BY_PROJECT_HEADER,
    ERROR_MESSAGE: s__(
      'UsageQuotas|An error occurred loading the transfer data. Please refresh the page to try again.',
    ),
    STATISTICS_CARD_TOTAL_VALUE: __('Unlimited'),
    STATISTICS_CARD_DESCRIPTION: s__('UsageQuotas|Namespace transfer data used'),
  },
  components: {
    GlAlert,
    StatisticsCard,
  },
  inject: ['fullPath'],
  data() {
    return {
      groupDataTransferEgress: {},
      hasError: false,
    };
  },
  apollo: {
    groupDataTransferEgress: {
      query: getGroupDataTransferEgress,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.group;
      },
      error() {
        this.hasError = true;
      },
    },
  },
  computed: {
    isGroupDataTransferEgressLoading() {
      return this.$apollo.queries.groupDataTransferEgress.loading;
    },
    egressNodes() {
      return this.groupDataTransferEgress?.dataTransfer?.egressNodes?.nodes || [];
    },
    combinedEgressNodes() {
      return this.egressNodes.reduce((accumulator, { totalEgress = '0' }) => {
        return accumulator + Number(totalEgress);
      }, 0);
    },
    formattedCombinedEgressNodes() {
      return numberToHumanSizeSplit(this.combinedEgressNodes);
    },
    combinedEgressNodesValue() {
      const [value] = this.formattedCombinedEgressNodes;
      return value;
    },
    combinedEgressNodesUnit() {
      const [, unit] = this.formattedCombinedEgressNodes;
      return unit;
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
    <statistics-card
      class="gl-mt-5"
      :usage-value="combinedEgressNodesValue"
      :usage-unit="combinedEgressNodesUnit"
      :total-value="$options.i18n.STATISTICS_CARD_TOTAL_VALUE"
      :description="$options.i18n.STATISTICS_CARD_DESCRIPTION"
      :loading="isGroupDataTransferEgressLoading"
    />
    <h4 class="gl-font-lg gl-mb-5">{{ $options.i18n.USAGE_BY_MONTH_HEADER }}</h4>
    <h4 class="gl-font-lg gl-mb-5">{{ $options.i18n.USAGE_BY_PROJECT_HEADER }}</h4>
  </div>
</template>
