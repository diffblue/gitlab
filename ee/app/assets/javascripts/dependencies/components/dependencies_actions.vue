<script>
import { GlButton, GlSorting, GlSortingItem, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import { SORT_FIELDS, SORT_ASCENDING } from '../store/modules/list/constants';

export default {
  i18n: {
    exportAsJson: s__('Dependencies|Export as JSON'),
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
  mixins: [glFeatureFlagsMixin()],
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
      buttonIcon() {
        return this.fetchingInProgress ? '' : 'export';
      },
      fetchingInProgress(state) {
        return state[this.namespace].fetchingInProgress;
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
      fetchExport(dispatch) {
        dispatch(`${this.namespace}/fetchExport`);
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
      v-gl-tooltip.hover
      :title="$options.i18n.exportAsJson"
      class="gl-ml-3"
      :icon="buttonIcon"
      data-testid="export"
      :loading="fetchingInProgress"
      @click="fetchExport"
    >
      {{ __('Export') }}
    </gl-button>
  </div>
</template>
