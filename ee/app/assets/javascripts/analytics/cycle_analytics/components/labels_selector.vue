<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlIcon,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapGetters } from 'vuex';
import Api from 'ee/api';
import { removeFlash } from '~/analytics/shared/utils';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { DATA_REFETCH_DELAY } from '../../shared/constants';

export default {
  name: 'LabelsSelector',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlIcon,
    GlLoadingIcon,
    GlSearchBoxByType,
  },
  props: {
    initialData: {
      type: Array,
      required: false,
      default: () => [],
    },
    maxLabels: {
      type: Number,
      required: false,
      default: 0,
    },
    multiselect: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedLabelIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    right: {
      type: Boolean,
      required: false,
      default: false,
    },
    dropdownItemClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      loading: false,
      searchTerm: '',
      labels: [],
    };
  },
  computed: {
    selectedLabel() {
      const { selectedLabelIds, labels = [] } = this;
      if (!selectedLabelIds.length || !labels.length) return null;
      return labels.find(({ id }) => selectedLabelIds.includes(id));
    },
    maxLabelsSelected() {
      return this.selectedLabelIds.length >= this.maxLabels;
    },
    noMatchingLabels() {
      return Boolean(this.searchTerm.length && !this.labels.length);
    },
  },
  watch: {
    searchTerm() {
      this.search();
    },
  },
  mounted() {
    if (!this.initialData.length) {
      this.fetchData();
    } else {
      this.labels = this.initialData;
    }
  },
  methods: {
    ...mapGetters(['currentGroupPath']),
    fetchData() {
      removeFlash();
      this.loading = true;
      return Api.cycleAnalyticsGroupLabels(this.currentGroupPath, {
        search: this.searchTerm,
        only_group_labels: true,
      })
        .then(({ data }) => {
          this.labels = data;
        })
        .catch(() => {
          createFlash({
            message: __('There was an error fetching label data for the selected group'),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    search: debounce(function debouncedSearch() {
      this.fetchData();
    }, DATA_REFETCH_DELAY),
    labelTitle(label) {
      // there are 2 possible endpoints for group labels
      // one returns label.name the other label.title
      return label?.name || label.title;
    },
    isSelectedLabel(id) {
      return Boolean(this.selectedLabelIds?.includes(id));
    },
    isDisabledLabel(id) {
      return Boolean(this.maxLabelsSelected && !this.isSelectedLabel(id));
    },
  },
};
</script>
<template>
  <gl-dropdown class="gl-w-full" toggle-class="gl-overflow-hidden" :right="right">
    <template #button-content>
      <slot name="label-dropdown-button">
        <span v-if="selectedLabel" class="gl-new-dropdown-button-text">
          <span
            :style="{ backgroundColor: selectedLabel.color }"
            class="d-inline-block dropdown-label-box"
          >
          </span>
          {{ labelTitle(selectedLabel) }}
        </span>
        <span v-else class="gl-new-dropdown-button-text">{{ __('Select a label') }}</span>
        <gl-icon class="dropdown-chevron" name="chevron-down" />
      </slot>
    </template>

    <slot name="label-dropdown-list-header">
      <gl-dropdown-section-header>{{ __('Select a label') }} </gl-dropdown-section-header>
    </slot>
    <div class="mb-3 px-3">
      <gl-search-box-by-type v-model.trim="searchTerm" />
    </div>
    <div class="mb-3 px-3">
      <gl-dropdown-item
        v-for="label in labels"
        :key="label.id"
        :class="{
          'pl-4': multiselect && !isSelectedLabel(label.id),
          'cursor-not-allowed': disabled,
        }"
        :active="isSelectedLabel(label.id)"
        @click.prevent="$emit('select-label', label.id)"
      >
        <gl-icon
          v-if="multiselect && isSelectedLabel(label.id)"
          class="text-gray-700 mr-1 vertical-align-middle"
          name="mobile-issue-close"
        />
        <span :style="{ backgroundColor: label.color }" class="d-inline-block dropdown-label-box">
        </span>
        {{ labelTitle(label) }}
      </gl-dropdown-item>
      <div v-show="loading" class="text-center">
        <gl-loading-icon :inline="true" size="md" />
      </div>
      <div v-show="noMatchingLabels" class="text-secondary">
        {{ __('No matching labels') }}
      </div>
    </div>
  </gl-dropdown>
</template>
