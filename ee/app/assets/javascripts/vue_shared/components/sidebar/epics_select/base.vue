<script>
import {
  GlLink,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapState, mapGetters, mapActions } from 'vuex';
import { IssuableStates } from '~/vue_shared/issuable/list/constants';
import { noneEpic } from 'ee/vue_shared/constants';
import { __, s__ } from '~/locale';
import { DropdownVariant, DATA_REFETCH_DELAY } from './constants';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';
import createStore from './store';

export const i18n = {
  selectEpic: s__('Epics|Select epic'),
  searchEpic: s__('Epics|Search epics'),
  assignEpic: s__('Epics|Assign Epic'),
  noMatch: __('No Matching Results'),
};

export default {
  i18n,
  noneEpic,
  store: createStore(),
  components: {
    GlLink,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlSearchBoxByType,
    DropdownValue,
    DropdownValueCollapsed,
  },
  props: {
    groupId: {
      type: Number,
      required: true,
    },
    issueId: {
      type: Number,
      required: false,
      default: 0,
    },
    epicIssueId: {
      type: Number,
      required: false,
      default: 0,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    initialEpic: {
      type: Object,
      required: true,
    },
    initialEpicLoading: {
      type: Boolean,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: DropdownVariant.Sidebar,
    },
    showHeader: {
      type: Boolean,
      required: false,
      default: true,
    },
    showOnlyOpenedEpics: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDropdownShowing: false,
      search: '',
    };
  },
  computed: {
    ...mapState([
      'epicSelectInProgress',
      'epicsFetchInProgress',
      'selectedEpic',
      'searchQuery',
      'selectedEpicIssueId',
    ]),
    ...mapGetters(['isDropdownVariantSidebar', 'isDropdownVariantStandalone', 'groupEpics']),
    dropdownButtonTextClass() {
      return {
        'is-default': this.isDropdownVariantStandalone,
        'dropdown-menu-toggle js-epic-select js-extra-options gl-py-3!': true,
      };
    },
    dropDownTitle() {
      return this.selectedEpic.title || this.$options.i18n.selectEpic;
    },
    dropdownClass() {
      if (this.isDropdownVariantSidebar) {
        return this.isDropdownShowing ? 'dropdown-menu-epics' : 'gl-display-none';
      }

      return 'dropdown-menu-epics';
    },
    dropdownHeaderText() {
      if (this.showHeader) {
        return this.$options.i18n.assignEpic;
      }

      return '';
    },
    isLoading() {
      return this.epicsFetchInProgress || this.epicSelectInProgress || this.initialEpicLoading;
    },
    epicListValid() {
      return this.groupEpics.length > 0 && !this.isLoading;
    },
    epicListNotValid() {
      return this.groupEpics.length === 0 && !this.isLoading;
    },
    fetchEpicParams() {
      if (this.showOnlyOpenedEpics) {
        return { state: IssuableStates.Opened };
      }
      return {};
    },
  },
  watch: {
    /**
     * When Issue is created from Boards
     * Issue ID is updated post-render
     * so we need to watch it to update in state
     */
    issueId() {
      this.setIssueId(this.issueId);
    },
    /**
     * When Issues are selected within Boards
     * `initialEpic` gets updated to reflect
     * underlying selection.
     */
    initialEpic() {
      this.setSelectedEpic(this.initialEpic);
      this.setSelectedEpicIssueId(this.epicIssueId);
    },
    /**
     * Initial Epic is loaded via separate Sidebar store
     * So we need to watch for updates before updating local store.
     */
    initialEpicLoading() {
      this.setSelectedEpic(this.initialEpic);
      this.setSelectedEpicIssueId(this.epicIssueId);
    },
    /**
     * Check if `searchQuery` presence has yielded any matching
     * epics, if not, dispatch `fetchEpics` with search query.
     */
    searchQuery(value) {
      if (value) {
        this.fetchEpics({ search: this.searchQuery, ...this.fetchEpicParams });
      } else {
        this.fetchEpics({ search: '', ...this.fetchEpicParams });
      }
    },
    search: debounce(function debouncedEpicSearch() {
      this.setSearchQuery(this.search);
    }, DATA_REFETCH_DELAY),
  },
  mounted() {
    this.setInitialData({
      variant: this.variant,
      groupId: this.groupId,
      issueId: this.issueId,
      selectedEpic: this.initialEpic,
      selectedEpicIssueId: this.epicIssueId,
    });
  },
  methods: {
    ...mapActions([
      'setInitialData',
      'setIssueId',
      'setSearchQuery',
      'setSelectedEpic',
      'setSelectedEpicIssueId',
      'fetchEpics',
      'assignIssueToEpic',
      'removeIssueFromEpic',
    ]),
    focusInput() {
      this.$refs.search.focusInput();
    },
    handleItemSelect(epic) {
      if (
        this.selectedEpicIssueId &&
        epic.id === this.$options.noneEpic.id &&
        epic.title === this.$options.noneEpic.title
      ) {
        this.removeIssueFromEpic(this.selectedEpic);
      } else if (this.issueId) {
        this.assignIssueToEpic(epic);
      } else {
        this.$emit('epicSelect', epic);
      }
    },
    hideDropdown() {
      this.isDropdownShowing = this.isDropdownVariantStandalone;
      this.$emit('hide');
    },
    toggleFormDropdown() {
      const { dropdown } = this.$refs.dropdown.$refs;
      this.isDropdownShowing = !this.isDropdownShowing;

      if (dropdown && this.isDropdownShowing) {
        dropdown.show();
        this.fetchEpics({ search: '', ...this.fetchEpicParams });
      }
    },
  },
};
</script>

<template>
  <div class="js-epic-block" :class="{ 'block epic': isDropdownVariantSidebar }">
    <div class="hide-collapsed epic-dropdown-container">
      <p
        v-if="isDropdownVariantSidebar"
        class="title gl-display-flex gl-justify-content-space-between"
      >
        <span>
          {{ __('Epic')
          }}<gl-loading-icon v-if="epicSelectInProgress" size="sm" class="gl-ml-2" :inline="true"
        /></span>

        <gl-link
          v-if="canEdit"
          ref="editButton"
          class="sidebar-dropdown-toggle"
          href="#"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ __('Edit') }}
        </gl-link>
      </p>

      <gl-dropdown
        v-if="canEdit || isDropdownVariantStandalone"
        ref="dropdown"
        :text="dropDownTitle"
        class="gl-w-full"
        :class="dropdownClass"
        :toggle-class="dropdownButtonTextClass"
        :header-text="dropdownHeaderText"
        @keydown.esc.native="hideDropdown"
        @hide="hideDropdown"
        @shown="focusInput"
        @toggle="toggleFormDropdown"
      >
        <template #header>
          <gl-search-box-by-type
            ref="search"
            v-model.trim="search"
            :placeholder="$options.i18n.searchEpic"
          />
        </template>
        <template v-if="epicListValid">
          <gl-dropdown-item
            :active="!selectedEpic"
            active-class="is-active"
            is-check-item
            :is-checked="selectedEpic.id === $options.noneEpic.id"
            @click="handleItemSelect($options.noneEpic)"
          >
            {{ __('No Epic') }}
          </gl-dropdown-item>
          <gl-dropdown-divider />
          <gl-dropdown-item
            v-for="epic in groupEpics"
            :key="epic.id"
            :active="selectedEpic.id === epic.id"
            active-class="is-active"
            is-check-item
            :is-checked="selectedEpic.id === epic.id"
            @click="handleItemSelect(epic)"
            >{{ epic.title }}</gl-dropdown-item
          >
        </template>
        <p v-else-if="epicListNotValid" class="gl-mx-5 gl-my-4">
          {{ $options.i18n.noMatch }}
        </p>
        <gl-loading-icon v-else size="sm" />
      </gl-dropdown>
    </div>

    <div v-if="isDropdownVariantSidebar && !isDropdownShowing">
      <dropdown-value-collapsed :epic="selectedEpic" />
      <dropdown-value :epic="selectedEpic">
        <slot></slot>
      </dropdown-value>
    </div>
  </div>
</template>
