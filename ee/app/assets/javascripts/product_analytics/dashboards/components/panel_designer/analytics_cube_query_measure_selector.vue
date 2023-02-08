<script>
import { GlLabel, GlButton } from '@gitlab/ui';
import { EVENTS_TYPES, EVENTS_DB_TABLE_NAME, MEASURE_COLOR } from '../../constants';

export default {
  name: 'AnalyticsQueryDesignerMeasureSelect',
  MEASURE_COLOR,
  components: {
    GlLabel,
    GlButton,
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
        let selectedEventType = '';

        if (EVENTS_TYPES.includes(this.measureType)) {
          this.setMeasures([`${EVENTS_DB_TABLE_NAME}.count`]);

          if (this.measureType === 'pageViews') {
            selectedEventType = 'pageview';
          }

          if (selectedEventType) {
            this.addFilters({
              member: `${EVENTS_DB_TABLE_NAME}.eventType`,
              operator: 'equals',
              values: [selectedEventType],
            });
          }
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
          <li>
            <gl-button
              icon="documents"
              category="tertiary"
              variant="confirm"
              data-testid="pageviews-button"
              @click="selectMeasure('pageViews')"
              >{{ s__('ProductAnalytics|Page Views') }}</gl-button
            >
            <div class="gl-text-secondary">
              {{ s__('ProductAnalytics|Measure all or specific Page Views') }}
            </div>
          </li>
          <li>
            <gl-button
              icon="bulb"
              category="tertiary"
              variant="confirm"
              data-testid="feature-button"
              @click="selectMeasure('featureUsages')"
              >{{ s__('ProductAnalytics|Feature usage') }}</gl-button
            >
            <div class="gl-text-secondary">
              {{ s__('ProductAnalytics|Track specific features') }}
            </div>
          </li>
          <li>
            <gl-button
              icon="check-circle"
              category="tertiary"
              variant="confirm"
              data-testid="clickevents-button"
              @click="selectMeasure('clickEvents')"
              >{{ s__('ProductAnalytics|Click Events') }}</gl-button
            >
            <div class="gl-text-secondary">{{ s__('ProductAnalytics|Any Click on elements') }}</div>
          </li>
          <li>
            <gl-button
              icon="monitor-lines"
              category="tertiary"
              variant="confirm"
              data-testid="events-button"
              @click="selectMeasure('events')"
              >{{ s__('ProductAnalytics|Events') }}</gl-button
            >
            <div class="gl-text-secondary">
              {{ s__('ProductAnalytics|Measure All tracked Events') }}
            </div>
          </li>
        </ul>
      </div>
      <div v-else-if="measureType === 'pageViews'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Page Views') }}</h3>
        <ul class="flex-list content-list">
          <li>
            <gl-button
              icon="details-block"
              category="tertiary"
              variant="confirm"
              data-testid="pageviews-all-button"
              @click="selectMeasure('pageViews', 'all')"
              >{{ s__('ProductAnalytics|All pages') }}</gl-button
            >
            <div class="gl-text-secondary">
              {{ s__('ProductAnalytics|Compares pageviews of all pages against each other') }}
            </div>
          </li>
        </ul>
      </div>

      <div v-else-if="measureType === 'featureUsages'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Feature Usage') }}</h3>
        <ul class="flex-list content-list">
          <li>
            <gl-button
              icon="details-block"
              category="tertiary"
              variant="confirm"
              data-testid="feature-all-button"
              @click="selectMeasure('featureUsages', 'all')"
              >{{ s__('ProductAnalytics|All features') }}</gl-button
            >
            <div class="gl-text-secondary">
              {{
                s__('ProductAnalytics|Compares feature usage of all features against each other')
              }}
            </div>
          </li>
        </ul>
      </div>
      <div v-else-if="measureType === 'clickEvents'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Click Events') }}</h3>
        <ul class="flex-list content-list">
          <li>
            <gl-button
              icon="details-block"
              category="tertiary"
              variant="confirm"
              data-testid="clickevents-all-button"
              @click="selectMeasure('clickEvents', 'all')"
              >{{ s__('ProductAnalytics|All clicks compared') }}</gl-button
            >
            <div class="gl-text-secondary">
              {{ s__('ProductAnalytics|Compares click events against each other') }}
            </div>
          </li>
        </ul>
      </div>
      <div v-else-if="measureType === 'events'">
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Events') }}</h3>
        <ul class="flex-list content-list">
          <li>
            <gl-button
              icon="details-block"
              category="tertiary"
              variant="confirm"
              data-testid="events-all-button"
              @click="selectMeasure('events', 'all')"
              >{{ s__('ProductAnalytics|All events compared') }}</gl-button
            >
            <div class="gl-text-secondary">
              {{ s__('ProductAnalytics|Compares all events against each other') }}
            </div>
          </li>
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
