<script>
import { GlButton, GlDropdown, GlDropdownItem, GlIcon, GlTooltipDirective } from '@gitlab/ui';
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
    GlDropdown,
    GlDropdownItem,
    GlIcon,
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
    sortOrderIcon() {
      return this.sortOrder === SORT_ASCENDING ? 'sort-lowest' : 'sort-highest';
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
    isCurrentSortField(id) {
      return id === this.sortField;
    },
  },
};
</script>

<template>
  <div class="btn-toolbar">
    <div class="btn-group flex-grow-1 mr-2">
      <gl-dropdown :text="sortFieldName" class="flex-grow-1 text-center" right>
        <gl-dropdown-item
          v-for="(name, id) in $options.i18n.sortFields"
          :key="id"
          @click="setSortField(id)"
        >
          <span class="d-flex">
            <gl-icon
              class="flex-shrink-0 gl-mr-2"
              :class="{ invisible: !isCurrentSortField(id) }"
              name="mobile-issue-close"
            />
            {{ name }}
          </span>
        </gl-dropdown-item>
      </gl-dropdown>
      <gl-button
        v-gl-tooltip
        :title="$options.i18n.sortDirectionLabel"
        :aria-label="$options.i18n.sortDirectionLabel"
        class="flex-grow-0 js-sort-order"
        @click="toggleSortOrder"
      >
        <gl-icon :name="sortOrderIcon" />
      </gl-button>
    </div>
    <gl-button
      v-gl-tooltip
      :href="downloadEndpoint"
      download="dependencies.json"
      :title="s__('Dependencies|Export as JSON')"
      class="js-download"
      icon="export"
    >
      {{ __('Export') }}
    </gl-button>
  </div>
</template>
