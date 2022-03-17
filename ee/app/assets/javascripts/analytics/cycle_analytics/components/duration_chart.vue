<script>
import { GlAlert, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { dataVizBlue500 } from '@gitlab/ui/scss_to_js/scss_variables';
import { mapState, mapGetters } from 'vuex';
import { dateFormats } from '~/analytics/shared/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import Scatterplot from '../../shared/components/scatterplot.vue';
import {
  DURATION_STAGE_TIME_DESCRIPTION,
  DURATION_STAGE_TIME_NO_DATA,
  DURATION_STAGE_TIME_LABEL,
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_TOTAL_TIME_NO_DATA,
  DURATION_TOTAL_TIME_LABEL,
} from '../constants';

export default {
  name: 'DurationChart',
  components: {
    GlAlert,
    GlIcon,
    Scatterplot,
    ChartSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
  },
  computed: {
    ...mapState(['selectedStage']),
    ...mapState('durationChart', ['isLoading', 'errorMessage']),
    ...mapGetters(['isOverviewStageSelected']),
    ...mapGetters('durationChart', ['durationChartPlottableData']),
    hasData() {
      return Boolean(!this.isLoading && this.durationChartPlottableData.length);
    },
    error() {
      if (this.errorMessage) {
        return this.errorMessage;
      }
      return this.isOverviewStageSelected
        ? DURATION_TOTAL_TIME_NO_DATA
        : DURATION_STAGE_TIME_NO_DATA;
    },
    title() {
      return this.isOverviewStageSelected
        ? DURATION_TOTAL_TIME_LABEL
        : sprintf(DURATION_STAGE_TIME_LABEL, {
            title: capitalizeFirstCharacter(this.selectedStage.title),
          });
    },
    tooltipText() {
      return this.isOverviewStageSelected
        ? DURATION_TOTAL_TIME_DESCRIPTION
        : DURATION_STAGE_TIME_DESCRIPTION;
    },
  },
  durationChartTooltipDateFormat: dateFormats.defaultDate,
  medianAdditionalOptions: {
    lineStyle: {
      color: dataVizBlue500,
    },
  },
};
</script>

<template>
  <chart-skeleton-loader v-if="isLoading" size="md" class="gl-my-4 gl-py-4" />
  <div v-else class="gl-display-flex gl-flex-direction-column" data-testid="vsa-duration-chart">
    <h4 class="gl-mt-0">
      {{ title }}&nbsp;<gl-icon v-gl-tooltip.hover name="information-o" :title="tooltipText" />
    </h4>
    <scatterplot
      v-if="hasData"
      :x-axis-title="s__('CycleAnalytics|Date')"
      :y-axis-title="s__('CycleAnalytics|Average time to completion')"
      :tooltip-date-format="$options.durationChartTooltipDateFormat"
      :scatter-data="durationChartPlottableData"
      :median-line-data="durationChartPlottableData"
      :median-line-options="$options.medianAdditionalOptions"
    />
    <gl-alert v-else variant="info" :dismissible="false" class="gl-mt-3">
      {{ error }}
    </gl-alert>
  </div>
</template>
