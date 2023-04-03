<script>
import { GlAlert } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { numberToHumanSizeSplit } from '~/lib/utils/number_utils';
import dateFormat from '~/lib/dateformat';
import { DEFAULT_PER_PAGE } from '~/api';
import getGroupDataTransferEgress from '../graphql/queries/get_group_data_transfer_egress.query.graphql';
import StatisticsCard from '../../components/statistics_card.vue';
import UsageByMonth from './usage_by_month.vue';
import UsageByProject from './usage_by_project.vue';

export default {
  i18n: {
    ERROR_MESSAGE: s__(
      'UsageQuotas|An error occurred loading the transfer data. Please refresh the page to try again.',
    ),
    STATISTICS_CARD_TOTAL_VALUE: __('Unlimited'),
    STATISTICS_CARD_DESCRIPTION: s__('UsageQuotas|Namespace transfer data used'),
  },
  components: {
    GlAlert,
    StatisticsCard,
    UsageByMonth,
    UsageByProject,
  },
  inject: ['fullPath'],
  data() {
    return {
      groupDataTransferEgress: {},
      hasError: false,
      pagination: {
        first: DEFAULT_PER_PAGE,
        after: null,
        last: null,
        before: null,
      },
      isLoadingProjects: true,
      isLoadingGroups: true,
    };
  },
  apollo: {
    groupDataTransferEgress: {
      query: getGroupDataTransferEgress,
      variables() {
        return {
          fullPath: this.fullPath,
          ...this.pagination,
        };
      },
      update(data) {
        return data.group;
      },
      result() {
        this.isLoadingProjects = false;
        this.isLoadingGroups = false;
      },
      error() {
        this.hasError = true;
        this.isLoadingProjects = false;
        this.isLoadingGroups = false;
      },
    },
  },
  computed: {
    projects() {
      return this.groupDataTransferEgress?.projects || {};
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
    usageByMonthData() {
      return this.egressNodes.map(({ date, totalEgress }) => {
        const month = dateFormat(new Date(date), 'mmm yyyy');

        return [month, totalEgress];
      });
    },
  },
  methods: {
    onAlertDismiss() {
      this.hasError = false;
    },
    onUsageByProjectNext(endCursor) {
      this.isLoadingProjects = true;
      this.pagination = {
        first: DEFAULT_PER_PAGE,
        after: endCursor,
        last: null,
        before: null,
      };
    },
    onUsageByProjectPrev(startCursor) {
      this.isLoadingProjects = true;
      this.pagination = {
        first: null,
        after: null,
        last: DEFAULT_PER_PAGE,
        before: startCursor,
      };
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
      :loading="isLoadingGroups"
    />
    <usage-by-month :chart-data="usageByMonthData" :loading="isLoadingGroups" />
    <usage-by-project
      :projects="projects"
      :loading="isLoadingProjects"
      @next="onUsageByProjectNext"
      @prev="onUsageByProjectPrev"
    />
  </div>
</template>
