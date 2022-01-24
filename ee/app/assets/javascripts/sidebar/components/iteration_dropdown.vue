<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlSearchBoxByType,
  GlDropdownSectionHeader,
  GlTooltipDirective,
  GlLoadingIcon,
} from '@gitlab/ui';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import {
  groupByIterationCadences,
  getIterationPeriod,
  getIterationTitle,
} from 'ee/iterations/utils';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { iterationSelectTextMap, iterationDisplayState } from '../constants';
import groupIterationsQuery from '../queries/iterations.query.graphql';

export default {
  noIteration: { text: iterationSelectTextMap.noIteration, id: null },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlSearchBoxByType,
    GlDropdownSectionHeader,
    GlLoadingIcon,
    IterationTitle,
  },
  mixins: [glFeatureFlagMixin()],
  apollo: {
    iterations: {
      query: groupIterationsQuery,
      debounce: 250,
      variables() {
        const search = this.searchTerm ? `"${this.searchTerm}"` : '';

        return {
          fullPath: this.fullPath,
          title: search,
          state: iterationDisplayState,
        };
      },
      update(data) {
        return data.group?.iterations?.nodes || [];
      },
      skip() {
        return !this.shouldFetch;
      },
    },
  },
  props: {
    fullPath: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      searchTerm: '',
      iterations: [],
      currentIteration: null,
      shouldFetch: false,
    };
  },
  computed: {
    cadenceTitle() {
      return this.currentIteration?.iterationCadence?.title;
    },
    iterationCadences() {
      return groupByIterationCadences(this.iterations);
    },
    dropdownSelectedText() {
      return this.currentIteration?.startDate || this.currentIteration?.period
        ? this.getIterationPeriod(this.currentIteration)
        : __('Select iteration');
    },
  },
  methods: {
    onClick(iteration) {
      if (iteration.id === this.currentIteration?.id) {
        this.currentIteration = null;
      } else {
        this.currentIteration = iteration;
      }

      this.$emit('onIterationSelect', this.currentIteration);
    },
    isIterationChecked(id) {
      return id === this.currentIteration?.id;
    },
    onDropdownShow() {
      this.shouldFetch = true;
    },
    getIterationPeriod,
    getIterationTitle,
  },
};
</script>

<template>
  <gl-dropdown :text="dropdownSelectedText" class="gl-w-full" block @show="onDropdownShow">
    <gl-dropdown-section-header class="gl-display-flex! gl-justify-content-center">{{
      __('Assign Iteration')
    }}</gl-dropdown-section-header>
    <gl-search-box-by-type v-model="searchTerm" />
    <gl-dropdown-item
      :is-check-item="true"
      :is-checked="isIterationChecked($options.noIteration.id)"
      @click="onClick($options.noIteration)"
    >
      {{ $options.noIteration.text }}
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <gl-loading-icon v-if="$apollo.queries.iterations.loading" size="sm" />
    <template v-else-if="!glFeatures.iterationCadences">
      <gl-dropdown-item
        v-for="iterationItem in iterations"
        :key="iterationItem.id"
        :is-check-item="true"
        :is-checked="isIterationChecked(iterationItem.id)"
        @click="onClick(iterationItem)"
      >
        {{ getIterationPeriod(iterationItem) }}
        <iteration-title v-if="getIterationTitle(iterationItem)">
          {{ getIterationTitle(iterationItem) }}
        </iteration-title>
      </gl-dropdown-item>
    </template>
    <template v-else>
      <template v-for="(cadence, index) in iterationCadences">
        <gl-dropdown-divider v-if="index !== 0" :key="index" />
        <gl-dropdown-section-header :key="cadence.title">
          {{ cadence.title }}
        </gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="iterationItem in cadence.iterations"
          :key="iterationItem.id"
          :is-check-item="true"
          :is-checked="isIterationChecked(iterationItem.id)"
          @click="onClick(iterationItem)"
        >
          {{ iterationItem.period }}
          <iteration-title v-if="getIterationTitle(iterationItem)">
            {{ getIterationTitle(iterationItem) }}
          </iteration-title>
        </gl-dropdown-item>
      </template>
    </template>
  </gl-dropdown>
</template>
