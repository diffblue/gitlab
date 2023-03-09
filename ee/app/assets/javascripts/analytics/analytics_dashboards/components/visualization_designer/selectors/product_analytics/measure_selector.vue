<script>
import { GlLabel, GlButton } from '@gitlab/ui';
import {
  EVENTS_DB_TABLE_NAME,
  SESSIONS_TABLE_NAME,
  MEASURE_COLOR,
  isTrackedEvent,
} from 'ee/analytics/analytics_dashboards/constants';
import VisualizationDesignerListOption from '../../visualization_designer_list_option.vue';

export default {
  name: 'ProductAnalyticsMeasureSelector',
  MEASURE_COLOR,
  components: {
    GlLabel,
    GlButton,
    VisualizationDesignerListOption,
  },
  props: {
    measures: {
      type: Array,
      required: true,
    },
    setMeasures: {
      type: Function,
      required: true,
    },
    filters: {
      type: Array,
      required: true,
    },
    setFilters: {
      type: Function,
      required: true,
    },
    addFilters: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      measureType: '',
      measureSubType: '',
    };
  },
  methods: {
    selectMeasure(measure, subMeasure) {
      this.measureType = measure;
      this.measureSubType = subMeasure;

      if (this.measureType && this.measureSubType) {
        const measureMap = {
          pageViews: [`${EVENTS_DB_TABLE_NAME}.pageViewsCount`],
          featureUsages: [`${EVENTS_DB_TABLE_NAME}.count`],
          clickEvents: [`${EVENTS_DB_TABLE_NAME}.count`],
          events: [`${EVENTS_DB_TABLE_NAME}.count`],
          uniqueUsers: [`${EVENTS_DB_TABLE_NAME}.uniqueUsersCount`],
          sessions: [`${SESSIONS_TABLE_NAME}.${this.measureSubType}`],
        };

        const eventTypeMap = {
          featureUsages: 'featureuse',
          clickEvents: 'click',
        };

        if (isTrackedEvent(this.measureType)) {
          this.setMeasures(measureMap[this.measureType]);
          const selectedEventType = eventTypeMap[this.measureType];
          if (selectedEventType) {
            this.addFilters({
              member: `${EVENTS_DB_TABLE_NAME}.eventType`,
              operator: 'equals',
              values: [selectedEventType],
            });
          }
        } else {
          this.setMeasures(measureMap[this.measureType]);
        }
      } else {
        this.setMeasures([]);
        this.setFilters([]);
      }

      this.$emit('measureSelected', measure, subMeasure);
    },
  },
};
</script>

<template>
  <div>
    <div v-if="measureType && measureSubType" data-testid="measure-summary">
      <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Measuring') }}</h3>
      <gl-label
        :title="measureType + '::' + measureSubType"
        :background-color="$options.MEASURE_COLOR"
        scoped
        show-close-button
        @close="selectMeasure('', '')"
      />
    </div>
    <div v-else>
      <div v-if="!measureType">
        <h3 class="gl-font-xlg">{{ s__('ProductAnalytics|What do you want to measure?') }}</h3>
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|User activity') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            icon="documents"
            data-testid="pageviews-button"
            :title="s__('ProductAnalytics|Page Views')"
            :description="s__('ProductAnalytics|Measure all or specific Page Views')"
            @click="selectMeasure('pageViews')"
          />
          <visualization-designer-list-option
            icon="bulb"
            data-testid="feature-button"
            :title="s__('ProductAnalytics|Feature Usages')"
            :description="s__('ProductAnalytics|Track specific features')"
            @click="selectMeasure('featureUsages')"
          />
          <visualization-designer-list-option
            icon="check-circle"
            data-testid="clickevents-button"
            :title="s__('ProductAnalytics|Click Events')"
            :description="s__('ProductAnalytics|Any Click on elements')"
            @click="selectMeasure('clickEvents')"
          />
          <visualization-designer-list-option
            icon="monitor-lines"
            data-testid="events-button"
            :title="s__('ProductAnalytics|Events')"
            :description="s__('ProductAnalytics|Measure All tracked Events')"
            @click="selectMeasure('events')"
          />
        </ul>
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Users') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            icon="users"
            data-testid="users-button"
            :title="s__('ProductAnalytics|Unique Users')"
            :description="s__('ProductAnalytics|Measure by unique users')"
            @click="selectMeasure('uniqueUsers', 'all')"
          />
        </ul>
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|User Sessions') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            data-testid="sessions-button"
            :title="s__('ProductAnalytics|Sessions')"
            :description="s__('ProductAnalytics|Measure all sessions')"
            @click="selectMeasure('sessions')"
          />
        </ul>
      </div>
      <div v-else-if="measureType === 'pageViews'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Page Views') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            data-testid="pageviews-all-button"
            :title="s__('ProductAnalytics|All Pages')"
            :description="
              s__('ProductAnalytics|Compares page views of all pages against each other')
            "
            @click="selectMeasure('pageViews', 'all')"
          />
        </ul>
      </div>

      <div v-else-if="measureType === 'featureUsages'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Feature Usages') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            data-testid="feature-all-button"
            :title="s__('ProductAnalytics|All Features')"
            :description="
              s__('ProductAnalytics|Compares feature usage of all features against each other')
            "
            @click="selectMeasure('featureUsages', 'all')"
          />
        </ul>
      </div>
      <div v-else-if="measureType === 'clickEvents'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Click Events') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            data-testid="clickevents-all-button"
            :title="s__('ProductAnalytics|All Clicks Compared')"
            :description="s__('ProductAnalytics|Compares click events against each other')"
            @click="selectMeasure('clickEvents', 'all')"
          />
        </ul>
      </div>
      <div v-else-if="measureType === 'events'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Events') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            data-testid="events-all-button"
            :title="s__('ProductAnalytics|All Events Compared')"
            :description="s__('ProductAnalytics|Compares all events against each other')"
            @click="selectMeasure('events', 'all')"
          />
        </ul>
      </div>
      <div v-else-if="measureType === 'sessions'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Sessions') }}</h3>
        <ul class="content-list">
          <visualization-designer-list-option
            data-testid="sessions-count-button"
            :title="s__('ProductAnalytics|All Sessions Compared')"
            :description="s__('ProductAnalytics|Compares all user sessions against each other')"
            @click="selectMeasure('sessions', 'count')"
          />
          <visualization-designer-list-option
            data-testid="sessions-avgduration-button"
            :title="s__('ProductAnalytics|Average Session Duration')"
            :description="s__('ProductAnalytics|Average duration in minutes')"
            @click="selectMeasure('sessions', 'averageDurationMinutes')"
          />
          <visualization-designer-list-option
            data-testid="sessions-avgperuser-button"
            :title="s__('ProductAnalytics|Average Per User')"
            :description="s__('ProductAnalytics|How many sessions a user has')"
            @click="selectMeasure('sessions', 'averagePerUser')"
          />
          <visualization-designer-list-option
            data-testid="sessions-repeat-button"
            :title="s__('ProductAnalytics|Repeat Visit Percentage')"
            :description="s__('ProductAnalytics|How often sessions are repeated')"
            @click="selectMeasure('sessions', 'repeatPercent')"
          />
        </ul>
      </div>
      <div v-if="measureType" class="gl-mt-6">
        <gl-button data-testid="measure-back-button" @click="selectMeasure('')">{{
          __('Back')
        }}</gl-button>
      </div>
    </div>
  </div>
</template>
