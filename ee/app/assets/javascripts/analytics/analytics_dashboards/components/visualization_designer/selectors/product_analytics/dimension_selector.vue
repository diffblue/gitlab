<script>
import { GRANULARITIES } from '@cubejs-client/vue';
import { GlLabel, GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { DATE_RANGE_FILTER_DIMENSIONS } from 'ee/analytics/analytics_dashboards/data_sources/cube_analytics';
import { s__, sprintf } from '~/locale';
import {
  EVENTS_DB_TABLE_NAME,
  DIMENSION_COLOR,
  ANALYTICS_FIELD_CATEGORIES,
  ANALYTICS_FIELDS,
} from 'ee/analytics/analytics_dashboards/constants';

export default {
  name: 'ProductAnalyticsDimensionSelector',
  GRANULARITIES,
  ANALYTICS_FIELD_CATEGORIES,
  ANALYTICS_FIELDS,
  DIMENSION_COLOR,
  components: {
    GlLabel,
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    dimensions: {
      type: Array,
      required: true,
    },
    timeDimensions: {
      type: Array,
      required: true,
    },
    measureType: {
      type: String,
      required: true,
    },
    measureSubType: {
      type: String,
      required: true,
    },
    addDimensions: {
      type: Function,
      required: true,
    },
    removeDimension: {
      type: Function,
      required: true,
    },
    setTimeDimensions: {
      type: Function,
      required: true,
    },
    removeTimeDimension: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      selectedDimensionMode: true,
    };
  },
  computed: {
    hasDimensions() {
      return this.dimensions.length > 0 || this.timeDimensions.length > 0;
    },
    dimensionSelectorVisible() {
      return this.selectedDimensionMode === true || !this.hasDimensions;
    },
  },
  methods: {
    selectDimension(dimensionField) {
      if (typeof dimensionField === 'string') {
        this.addDimensions(`${EVENTS_DB_TABLE_NAME}.${dimensionField}`);
      } else {
        dimensionField.forEach((dimension) => {
          this.addDimensions(`${EVENTS_DB_TABLE_NAME}.${dimension}`);
        });
      }

      this.selectedDimensionMode = false;
    },
    setGranularity(selectedGranularity) {
      const dimensionFieldName =
        DATE_RANGE_FILTER_DIMENSIONS[
          this.measureType === 'sessions' ? this.measureType : 'trackedevents'
        ];

      this.setTimeDimensions([{ dimension: dimensionFieldName, granularity: selectedGranularity }]);
      this.selectedDimensionMode = false;
    },
    showDimensionMode() {
      this.selectedDimensionMode = true;
    },
    timeDimensionGranularityTitle(granularity) {
      return sprintf(s__('ProductAnalytics|Events grouped by %{granularity}'), {
        granularity,
      });
    },
    getAnalyticsFieldsByCategory(selectedCategory) {
      return this.$options.ANALYTICS_FIELDS.filter((field) => {
        return field.category === selectedCategory;
      });
    },
    getAnalyticsFieldTestId(field) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${field.category}-${
        typeof field.dbField === 'string' ? field.dbField : field.dbField.join('-')
      }-button`;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="hasDimensions" data-testid="dimension-summary">
      <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Dimensions') }}</h3>
      <div v-for="dimension in dimensions" :key="dimension.index">
        <gl-label
          :title="dimension.shortTitle"
          :description="dimension.title"
          :background-color="$options.DIMENSION_COLOR"
          class="gl-mr-2 gl-mb-2"
          show-close-button
          @close="removeDimension(dimension)"
        />
      </div>
      <div v-for="timeDimension in timeDimensions" :key="timeDimension.index">
        <gl-label
          :title="timeDimensionGranularityTitle(timeDimension.granularity)"
          :description="timeDimension.title"
          :background-color="$options.DIMENSION_COLOR"
          class="gl-mr-2 gl-mb-2"
          show-close-button
          @close="removeTimeDimension(timeDimension)"
        />
      </div>
      <div v-if="!selectedDimensionMode" class="gl-mt-2">
        <gl-button data-testid="another-dimension-button" @click="showDimensionMode">{{
          s__('ProductAnalytics|Add another dimension')
        }}</gl-button>
      </div>
    </div>
    <div v-if="dimensionSelectorVisible">
      <div>
        <h3 class="gl-font-xlg">
          {{ s__('ProductAnalytics|On what do you want to get insights?') }}
        </h3>
        <h3 class="gl-font-lg">{{ s__('ProductAnalytics|Events over time') }}</h3>
        <div>
          <gl-dropdown block text="grouped by" data-testid="event-granularities-dd">
            <gl-dropdown-item
              v-for="granularity in $options.GRANULARITIES"
              :key="granularity.name"
              @click="setGranularity(granularity.name)"
              >{{ granularity.title }}</gl-dropdown-item
            >
          </gl-dropdown>
        </div>
        <div v-if="measureType !== 'sessions'">
          <ul v-if="measureType === 'events'" class="content-list">
            <li>
              <gl-button
                icon="documents"
                category="tertiary"
                variant="confirm"
                @click="selectDimension('eventType')"
                >{{ s__('ProductAnalytics|Event Type') }}</gl-button
              >
            </li>
          </ul>
          <div
            v-for="fieldCategory in $options.ANALYTICS_FIELD_CATEGORIES"
            :key="fieldCategory.index"
          >
            <h3 class="gl-font-lg">
              {{ fieldCategory.name }}
            </h3>
            <ul class="content-list">
              <li
                v-for="field in getAnalyticsFieldsByCategory(fieldCategory.category)"
                :key="field.index"
              >
                <gl-button
                  :icon="field.icon"
                  :data-testid="getAnalyticsFieldTestId(field)"
                  category="tertiary"
                  variant="confirm"
                  @click="selectDimension(field.dbField)"
                  >{{ field.name }}</gl-button
                >
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div v-if="dimensions && dimensions.length > 0" class="gl-mt-6">
        <gl-button data-testid="dimension-back-button" @click="selectDimension('')">{{
          __('Back')
        }}</gl-button>
      </div>
    </div>
  </div>
</template>
