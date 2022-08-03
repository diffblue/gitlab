<script>
import {
  GlSearchBoxByType,
  GlDropdown,
  GlDropdownItem,
  GlButton,
  GlModal,
  GlSprintf,
  GlModalDirective,
} from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { s__, __, sprintf } from '~/locale';
import { DEFAULT_SEARCH_DELAY, ACTION_TYPES, FILTER_STATES, RESYNC_MODAL_ID } from '../constants';

export default {
  name: 'GeoReplicableFilterBar',
  i18n: {
    resyncAll: s__('Geo|Resync all'),
    resyncAllReplicables: s__('Geo|Resync all %{total}%{replicableType}'),
    dropdownTitle: s__('Geo|Filter by status'),
    searchPlaceholder: s__('Geo|Filter by name'),
    modalBody: s__(
      'Geo|This will resync all %{replicableType}. It may take some time to complete. Are you sure you want to continue?',
    ),
  },
  components: {
    GlSearchBoxByType,
    GlDropdown,
    GlDropdownItem,
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModalDirective,
  },
  computed: {
    ...mapState(['currentFilterIndex', 'filterOptions', 'searchFilter', 'paginationData']),
    ...mapGetters(['replicableTypeName']),
    search: {
      get() {
        return this.searchFilter;
      },
      set(val) {
        this.setSearch(val);
        this.fetchReplicableItems();
      },
    },
    hasReplicableItems() {
      return this.paginationData.total > 0;
    },
    resyncText() {
      return sprintf(this.$options.i18n.resyncAllReplicables, {
        replicableType: this.replicableTypeName,
        total: this.paginationData.total > 1 ? `${this.paginationData.total} ` : null,
      });
    },
  },
  methods: {
    ...mapActions(['setFilter', 'setSearch', 'fetchReplicableItems', 'initiateAllReplicableSyncs']),
    filterChange(filterIndex) {
      this.setFilter(filterIndex);
      this.fetchReplicableItems();
    },
  },
  actionTypes: ACTION_TYPES,
  filterStates: FILTER_STATES,
  debounce: DEFAULT_SEARCH_DELAY,
  MODAL_PRIMARY_ACTION: {
    text: s__('Geo|Resync all'),
  },
  MODAL_CANCEL_ACTION: {
    text: __('Cancel'),
  },
  RESYNC_MODAL_ID,
};
</script>

<template>
  <nav class="gl-bg-gray-50 gl-p-5">
    <div class="gl-display-grid geo-replicable-filter-grid gl-gap-3">
      <div
        class="gl-display-flex gl-align-items-center gl-flex-direction-column gl-sm-flex-direction-row"
      >
        <gl-dropdown :text="$options.i18n.dropdownTitle" class="gl-w-full">
          <gl-dropdown-item
            v-for="(filter, index) in filterOptions"
            :key="index"
            :class="{ 'gl-bg-gray-50': index === currentFilterIndex }"
            @click="filterChange(index)"
          >
            <span v-if="filter === $options.filterStates.ALL"
              >{{ filter.label }} {{ replicableTypeName }}</span
            >
            <span v-else>{{ filter.label }}</span>
          </gl-dropdown-item>
        </gl-dropdown>
        <gl-search-box-by-type
          v-model="search"
          :debounce="$options.debounce"
          class="gl-w-full gl-mt-3 gl-ml-0 gl-sm-mt-0 gl-sm-ml-3"
          :placeholder="$options.i18n.searchPlaceholder"
        />
      </div>
      <gl-button
        v-if="hasReplicableItems"
        v-gl-modal-directive="$options.RESYNC_MODAL_ID"
        class="gl-ml-auto"
        >{{ $options.i18n.resyncAll }}</gl-button
      >
    </div>
    <gl-modal
      :modal-id="$options.RESYNC_MODAL_ID"
      :title="resyncText"
      :action-primary="$options.MODAL_PRIMARY_ACTION"
      :action-cancel="$options.MODAL_CANCEL_ACTION"
      size="sm"
      @primary="initiateAllReplicableSyncs($options.actionTypes.RESYNC)"
    >
      <gl-sprintf :message="$options.i18n.modalBody">
        <template #replicableType>{{ replicableTypeName }}</template>
      </gl-sprintf>
    </gl-modal>
  </nav>
</template>
