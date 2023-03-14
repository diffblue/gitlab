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
import { groupByIterationCadences, getIterationPeriod } from 'ee/iterations/utils';
import { STATUS_OPEN } from '~/issues/constants';
import { __ } from '~/locale';
import { iterationSelectTextMap } from '../../constants';
import groupIterationsQuery from '../../queries/group_iterations.query.graphql';

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
  apollo: {
    iterations: {
      query: groupIterationsQuery,
      debounce: 250,
      variables() {
        const search = this.searchTerm ? `"${this.searchTerm}"` : '';

        return {
          fullPath: this.fullPath,
          title: search,
          state: STATUS_OPEN,
        };
      },
      update(data) {
        return data.workspace?.attributes?.nodes || [];
      },
      skip() {
        return !this.shouldFetch;
      },
    },
  },
  inject: ['fullPath'],
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
      return this.currentIteration?.period || __('Select iteration');
    },
    dropdownHeaderText() {
      return __('Assign Iteration');
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
    setFocus() {
      this.$refs.search.focusInput();
    },
    getIterationPeriod,
  },
};
</script>

<template>
  <gl-dropdown
    :text="dropdownSelectedText"
    :header-text="dropdownHeaderText"
    class="gl-w-full"
    block
    @show="onDropdownShow"
    @shown="setFocus"
  >
    <template #header>
      <gl-search-box-by-type ref="search" v-model="searchTerm" />
    </template>
    <gl-dropdown-item
      is-check-item
      :is-checked="isIterationChecked($options.noIteration.id)"
      @click="onClick($options.noIteration)"
    >
      {{ $options.noIteration.text }}
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <gl-loading-icon v-if="$apollo.queries.iterations.loading" size="sm" />
    <template v-else>
      <template v-for="(cadence, index) in iterationCadences">
        <gl-dropdown-divider v-if="index !== 0" :key="index" />
        <gl-dropdown-section-header :key="cadence.title">
          {{ cadence.title }}
        </gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="iterationItem in cadence.iterations"
          :key="iterationItem.id"
          is-check-item
          :is-checked="isIterationChecked(iterationItem.id)"
          @click="onClick(iterationItem)"
        >
          {{ iterationItem.period }}
          <iteration-title v-if="iterationItem.title" :title="iterationItem.title" />
        </gl-dropdown-item>
      </template>
    </template>
  </gl-dropdown>
</template>
