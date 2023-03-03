<script>
import { GlDropdownDivider, GlDropdownSectionHeader, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { groupByIterationCadences, getIterationPeriod } from 'ee/iterations/utils';
import { createAlert } from '~/alert';
import { TYPENAME_ITERATIONS_CADENCE } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import { OPERATOR_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import { DEFAULT_CADENCES, DEFAULT_ITERATIONS } from '../constants';

export default {
  components: {
    BaseToken,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlFilteredSearchSuggestion,
    IterationTitle,
  },
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
    defaultCadenceOptions() {
      return !this.config.hideDefaultCadenceOptions && this.value.operator === OPERATOR_IS
        ? DEFAULT_CADENCES
        : [];
    },
  },
  methods: {
    getActiveIteration(iterations, data) {
      if (data?.includes('&')) {
        const iterationCadenceId = this.getIterationCadenceId(data);
        const iteration = iterations.find(
          (i) =>
            i?.iterationCadence?.id ===
            convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, iterationCadenceId),
        );
        return iteration?.iterationCadence;
      }
      return iterations.find((iteration) => this.getId(iteration) === data);
    },
    groupIterationsByCadence(iterations) {
      return groupByIterationCadences(iterations);
    },
    fetchIterations(searchTerm) {
      this.loading = true;
      if (searchTerm?.includes('&')) {
        this.config
          .fetchIterationCadences(this.getIterationCadenceId(searchTerm))
          .then((response) => {
            this.iterations = [
              {
                iterationCadence: response[0],
              },
            ];
          })
          .catch((error) => {
            createAlert({ message: this.$options.i18n.errorMessage, captureError: true, error });
          })
          .finally(() => {
            this.loading = false;
          });
      } else {
        this.config
          .fetchIterations(searchTerm)
          .then((response) => {
            this.iterations = Array.isArray(response) ? response : response.data;
          })
          .catch(() => {
            createAlert({ message: this.$options.i18n.errorMessage });
          })
          .finally(() => {
            this.loading = false;
          });
      }
    },
    getId(option) {
      return getIdFromGraphQLId(option.id).toString();
    },
    getIterationCadenceId(input) {
      return input.split('&')[1];
    },
    getIterationOption(input) {
      return input.split('&')[0];
    },
    iterationTokenText(iterationOrCadence, inputValue) {
      if (iterationOrCadence?.id?.includes(TYPENAME_ITERATIONS_CADENCE)) {
        return `${this.getIterationOption(inputValue)}::${iterationOrCadence.title}`;
      }
      const cadenceTitle = iterationOrCadence.iterationCadence.title;
      return `${cadenceTitle} ${getIterationPeriod(iterationOrCadence)}`;
    },
  },
  i18n: {
    errorMessage: __('There was a problem fetching iterations.'),
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
    v-bind="$attrs"
    @fetch-suggestions="fetchIterations"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? iterationTokenText(activeTokenValue, inputValue) : inputValue }}
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
          v-for="option in defaultCadenceOptions"
          :key="`${option.value}-${index}`"
          :value="`${option.value}&${getId(cadence)}`"
        >
          {{ option.text }}
        </gl-filtered-search-suggestion>
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
