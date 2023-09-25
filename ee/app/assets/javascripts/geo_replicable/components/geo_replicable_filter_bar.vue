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
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import { s__, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  DEFAULT_SEARCH_DELAY,
  ACTION_TYPES,
  FILTER_STATES,
  GEO_BULK_ACTION_MODAL_ID,
  FILTER_OPTIONS,
} from '../constants';

export default {
  name: 'GeoReplicableFilterBar',
  i18n: {
    resyncAll: s__('Geo|Resync all'),
    reverifyAll: s__('Geo|Reverify all'),
    modalTitle: s__('Geo|%{action} %{replicableType}'),
    dropdownTitle: s__('Geo|Filter by status'),
    searchPlaceholder: s__('Geo|Filter by name'),
    modalBody: s__(
      'Geo|This will %{action} %{replicableType}. It may take some time to complete. Are you sure you want to continue?',
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
  mixins: [glFeatureFlagMixin()],
  data() {
    return {
      modalAction: null,
    };
  },
  computed: {
    ...mapState(['statusFilter', 'searchFilter', 'replicableItems', 'verificationEnabled']),
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
      return this.replicableItems.length > 0;
    },
    showBulkActions() {
      return this.glFeatures.geoRegistriesUpdateMutation && this.hasReplicableItems;
    },
    showSearch() {
      // To be implemented via https://gitlab.com/gitlab-org/gitlab/-/issues/411982
      return false;
    },
    modalTitle() {
      return sprintf(this.$options.i18n.modalTitle, {
        action: this.readableModalAction && capitalizeFirstCharacter(this.readableModalAction),
        replicableType: this.replicableTypeName,
      });
    },
    readableModalAction() {
      return this.modalAction?.replace('_', ' ');
    },
  },
  methods: {
    ...mapActions([
      'setStatusFilter',
      'setSearch',
      'fetchReplicableItems',
      'initiateAllReplicableAction',
    ]),
    filterChange(filter) {
      this.setStatusFilter(filter);
      this.fetchReplicableItems();
    },
    setModalData(action) {
      this.modalAction = action;
    },
  },
  actionTypes: ACTION_TYPES,
  filterStates: FILTER_STATES,
  filterOptions: FILTER_OPTIONS,
  debounce: DEFAULT_SEARCH_DELAY,
  GEO_BULK_ACTION_MODAL_ID,
};
</script>

<template>
  <nav class="gl-bg-gray-50 gl-p-5">
    <div class="gl-display-grid geo-replicable-filter-grid gl-gap-3">
      <div
        class="gl-display-flex gl-align-items-center gl-flex-direction-column gl-sm-flex-direction-row"
      >
        <gl-dropdown :text="$options.i18n.dropdownTitle" class="gl-w-half">
          <gl-dropdown-item
            v-for="filter in $options.filterOptions"
            :key="filter.value"
            :class="{ 'gl-bg-gray-50': filter.value === statusFilter }"
            @click="filterChange(filter.value)"
          >
            <span v-if="filter === $options.filterStates.ALL"
              >{{ filter.label }} {{ replicableTypeName }}</span
            >
            <span v-else>{{ filter.label }}</span>
          </gl-dropdown-item>
        </gl-dropdown>
        <gl-search-box-by-type
          v-if="showSearch"
          v-model="search"
          :debounce="$options.debounce"
          class="gl-w-full gl-mt-3 gl-ml-0 gl-sm-mt-0 gl-sm-ml-3"
          :placeholder="$options.i18n.searchPlaceholder"
        />
      </div>
      <div v-if="showBulkActions" class="gl-ml-auto">
        <gl-button
          v-gl-modal-directive="$options.GEO_BULK_ACTION_MODAL_ID"
          data-testid="geo-resync-all"
          @click="setModalData($options.actionTypes.RESYNC_ALL)"
          >{{ $options.i18n.resyncAll }}</gl-button
        >
        <gl-button
          v-if="verificationEnabled"
          v-gl-modal-directive="$options.GEO_BULK_ACTION_MODAL_ID"
          data-testid="geo-reverify-all"
          @click="setModalData($options.actionTypes.REVERIFY_ALL)"
          >{{ $options.i18n.reverifyAll }}</gl-button
        >
      </div>
    </div>
    <gl-modal
      :modal-id="$options.GEO_BULK_ACTION_MODAL_ID"
      :title="modalTitle"
      size="sm"
      @primary="initiateAllReplicableAction({ action: modalAction })"
    >
      <gl-sprintf :message="$options.i18n.modalBody">
        <template #action>{{ readableModalAction }}</template>
        <template #replicableType>{{ replicableTypeName }}</template>
      </gl-sprintf>
    </gl-modal>
  </nav>
</template>
