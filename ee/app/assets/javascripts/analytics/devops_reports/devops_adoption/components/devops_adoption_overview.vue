<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import {
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
  DEVOPS_ADOPTION_OVERALL_CONFIGURATION,
  I18N_TABLE_HEADER_TEXT,
} from '../constants';
import DevopsAdoptionOverviewCard from './devops_adoption_overview_card.vue';
import DevopsAdoptionOverviewChart from './devops_adoption_overview_chart.vue';
import DevopsAdoptionOverviewTable from './devops_adoption_overview_table.vue';

export default {
  name: 'DevopsAdoptionOverview',
  components: {
    DevopsAdoptionOverviewCard,
    DevopsAdoptionOverviewChart,
    DevopsAdoptionOverviewTable,
    GlLoadingIcon,
  },
  inject: {
    groupGid: {
      default: null,
    },
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    timestamp: {
      type: String,
      required: true,
    },
  },
  computed: {
    featuresData() {
      return DEVOPS_ADOPTION_TABLE_CONFIGURATION.map((item) => ({
        ...item,
        featureMeta: item.cols.map((feature) => ({
          title: feature.label,
          adopted: this.data.nodes?.some((node) =>
            node.latestSnapshot ? node.latestSnapshot[feature.key] : false,
          ),
        })),
      }));
    },
    overallData() {
      return {
        ...DEVOPS_ADOPTION_OVERALL_CONFIGURATION,
        featureMeta: this.featuresData.reduce(
          (features, section) => [...features, ...section.featureMeta],
          [],
        ),
        displayMeta: false,
      };
    },
    overviewData() {
      return [this.overallData, ...this.featuresData];
    },
    headerText() {
      return sprintf(I18N_TABLE_HEADER_TEXT, { timestamp: this.timestamp });
    },
  },
};
</script>
<template>
  <gl-loading-icon v-if="loading" size="lg" class="gl-mt-5" />
  <div v-else data-testid="overview-container">
    <p class="gl-text-gray-400 gl-my-3" data-testid="overview-container-header">{{ headerText }}</p>
    <div
      class="gl-display-flex gl-justify-content-space-between gl-flex-direction-column gl-md-flex-direction-row gl-mt-5"
    >
      <devops-adoption-overview-card
        v-for="item in overviewData"
        :key="item.title"
        class="gl-mb-5"
        :icon="item.icon"
        :title="item.title"
        :variant="item.variant"
        :feature-meta="item.featureMeta"
        :display-meta="item.displayMeta"
      />
    </div>
    <devops-adoption-overview-chart v-if="groupGid" class="gl-mb-7" />
    <devops-adoption-overview-table :data="data" v-on="$listeners" />
  </div>
</template>
