<script>
import { GlButton, GlSorting, GlSortingItem, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import { SORT_FIELDS, SORT_ASCENDING } from '../store/modules/list/constants';

export default {
  i18n: {
    sortDirectionLabel: __('Sort direction'),
    sortFields: SORT_FIELDS,
  },
  name: 'DependenciesActions',
  components: {
    GlButton,
    GlSorting,
    GlSortingItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    namespace: {
      type: String,
      required: true,
      validator: (value) =>
        Object.values(DEPENDENCY_LIST_TYPES).some(({ namespace }) => value === namespace),
    },
  },
  computed: {
    isSortAscending() {
      return this.sortOrder === SORT_ASCENDING;
    },
    ...mapState({
      sortField(state) {
        return state[this.namespace].sortField;
      },
      sortOrder(state) {
        return state[this.namespace].sortOrder;
      },
      downloadEndpoint(state, getters) {
        return getters[`${this.namespace}/downloadEndpoint`];
      },
    }),
    sortFieldName() {
      return this.$options.i18n.sortFields[this.sortField];
    },
  },
  methods: {
    ...mapActions({
      setSortField(dispatch, field) {
        dispatch(`${this.namespace}/setSortField`, field);
      },
      toggleSortOrder(dispatch) {
        dispatch(`${this.namespace}/toggleSortOrder`);
      },
    }),
    isCurrentSortField(field) {
      return field === this.sortField;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <gl-sorting
      :text="sortFieldName"
      :is-ascending="isSortAscending"
      :sort-direction-tool-tip="$options.i18n.sortDirectionLabel"
      class="gl-flex-grow-1"
      dropdown-class="gl-flex-grow-1"
      sort-direction-toggle-class="gl-flex-grow-0!"
      @sortDirectionChange="toggleSortOrder"
    >
      <gl-sorting-item
        v-for="(name, field) in $options.i18n.sortFields"
        :key="field"
        :active="isCurrentSortField(field)"
        @click="setSortField(field)"
      >
        {{ name }}
      </gl-sorting-item>
    </gl-sorting>
    <gl-button
      v-gl-tooltip
      :href="downloadEndpoint"
      download="dependencies.json"
      :title="s__('Dependencies|Export as JSON')"
      class="gl-ml-3"
      icon="export"
      data-testid="export"
    >
      {{ __('Export') }}
    </gl-button>
  </div>
</template>
