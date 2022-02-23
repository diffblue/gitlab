<script>
import { GlDropdownDivider, GlDropdownSectionHeader, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { groupByIterationCadences, getIterationPeriod } from 'ee/iterations/utils';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import { DEFAULT_ITERATIONS } from '../constants';

export default {
  components: {
    BaseToken,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlFilteredSearchSuggestion,
    IterationTitle,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      iterations: this.config.initialIterations || [],
      loading: false,
    };
  },
  computed: {
    defaultIterations() {
      return this.config.defaultIterations || DEFAULT_ITERATIONS;
    },
  },
  methods: {
    getActiveIteration(iterations, data) {
      return iterations.find((iteration) => this.getId(iteration) === data);
    },
    groupIterationsByCadence(iterations) {
      return groupByIterationCadences(iterations);
    },
    fetchIterations(searchTerm) {
      this.loading = true;
      this.config
        .fetchIterations(searchTerm)
        .then((response) => {
          this.iterations = Array.isArray(response) ? response : response.data;
        })
        .catch(() => {
          createFlash({ message: __('There was a problem fetching iterations.') });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    getId(iteration) {
      return getIdFromGraphQLId(iteration.id).toString();
    },
    iterationTokenText(iteration) {
      const cadenceTitle = iteration.iterationCadence.title;
      return `${cadenceTitle} ${getIterationPeriod(iteration)}`;
    },
  },
};
</script>

<template>
  <base-token
    :active="active"
    :config="config"
    :value="value"
    :default-suggestions="defaultIterations"
    :suggestions="iterations"
    :suggestions-loading="loading"
    :get-active-token-value="getActiveIteration"
    @fetch-suggestions="fetchIterations"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? iterationTokenText(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <template v-for="(cadence, index) in groupIterationsByCadence(suggestions)">
        <gl-dropdown-divider v-if="index !== 0" :key="index" />
        <gl-dropdown-section-header
          :key="cadence.title"
          class="gl-overflow-hidden"
          :title="cadence.title"
        >
          {{ cadence.title }}
        </gl-dropdown-section-header>
        <gl-filtered-search-suggestion
          v-for="iteration in cadence.iterations"
          :key="iteration.id"
          :value="getId(iteration)"
        >
          {{ iteration.period }}
          <iteration-title v-if="iteration.title" :title="iteration.title" />
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </base-token>
</template>
