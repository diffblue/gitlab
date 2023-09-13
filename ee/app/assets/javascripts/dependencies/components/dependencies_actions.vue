<script>
import { GlSorting, GlSortingItem } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { omit } from 'lodash';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { NAMESPACE_PROJECT } from '../constants';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import {
  SORT_FIELDS_PROJECT,
  SORT_FIELDS_GROUP,
  SORT_ASCENDING,
  SORT_FIELD_LICENSE,
} from '../store/modules/list/constants';

export default {
  i18n: {
    sortDirectionLabel: __('Sort direction'),
  },
  name: 'DependenciesActions',
  components: {
    GlSorting,
    GlSortingItem,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['namespaceType'],
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
    }),
    sortFieldName() {
      return this.sortFields[this.sortField];
    },
    sortFields() {
      const groupFields = this.glFeatures.groupLevelLicenses
        ? SORT_FIELDS_GROUP
        : omit(SORT_FIELDS_GROUP, SORT_FIELD_LICENSE);

      return this.isProjectNamespace ? SORT_FIELDS_PROJECT : groupFields;
    },
    isProjectNamespace() {
      return this.namespaceType === NAMESPACE_PROJECT;
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
  <div
    class="gl-display-flex gl-p-5 gl-bg-gray-10 gl-border-t-1 gl-border-t-solid gl-border-gray-100"
  >
    <gl-sorting
      :text="sortFieldName"
      :is-ascending="isSortAscending"
      :sort-direction-tool-tip="$options.i18n.sortDirectionLabel"
      class="gl-ml-auto"
      dropdown-class="gl-flex-grow-1"
      sort-direction-toggle-class="gl-flex-grow-0!"
      @sortDirectionChange="toggleSortOrder"
    >
      <gl-sorting-item
        v-for="(name, field) in sortFields"
        :key="field"
        :active="isCurrentSortField(field)"
        @click="setSortField(field)"
      >
        {{ name }}
      </gl-sorting-item>
    </gl-sorting>
  </div>
</template>
