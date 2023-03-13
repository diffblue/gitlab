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
import { mapGetters, mapState } from 'vuex';
import { getGroupLabels } from 'ee/api/analytics_api';
import { removeFlash } from '~/analytics/shared/utils';
import { createAlert } from '~/alert';
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
    selectedLabelNames: {
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
    ...mapState(['defaultGroupLabels']),
    selectedLabel() {
      const { selectedLabelNames, labels = [] } = this;
      if (!selectedLabelNames.length || !labels.length) return null;
      return labels.find(({ title }) => selectedLabelNames.includes(title));
    },
    maxLabelsSelected() {
      return this.selectedLabelNames.length >= this.maxLabels;
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
    if (!this.defaultGroupLabels?.length) {
      this.fetchData();
    } else {
      this.labels = this.defaultGroupLabels;
    }
  },
  methods: {
    ...mapGetters(['namespacePath']),
    fetchData() {
      removeFlash();
      this.loading = true;
      return getGroupLabels(this.namespacePath, {
        search: this.searchTerm,
        only_group_labels: true,
      })
        .then(({ data }) => {
          this.labels = data;
        })
        .catch(() => {
          createAlert({
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
      return Boolean(this.selectedLabelNames?.includes(id));
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
        <span v-if="selectedLabel" class="gl-dropdown-button-text">
          <span
            :style="{ backgroundColor: selectedLabel.color }"
            class="gl-display-inline-block dropdown-label-box"
          >
          </span>
          {{ labelTitle(selectedLabel) }}
        </span>
        <span v-else class="gl-dropdown-button-text">{{ __('Select a label') }}</span>
        <gl-icon class="dropdown-chevron" name="chevron-down" />
      </slot>
    </template>

    <slot name="label-dropdown-list-header">
      <gl-dropdown-section-header>{{ __('Select a label') }} </gl-dropdown-section-header>
    </slot>
    <div class="gl-mb-5 gl-px-5">
      <gl-search-box-by-type v-model.trim="searchTerm" />
    </div>
    <div class="gl-mb-5 gl-px-5">
      <gl-dropdown-item
        v-for="label in labels"
        :key="label.id"
        :class="{
          'gl-pl-6!': !isSelectedLabel(labelTitle(label)),
          'gl-cursor-not-allowed': disabled,
        }"
        :active="isSelectedLabel(labelTitle(label))"
        :is-checked="multiselect && isSelectedLabel(labelTitle(label))"
        :is-check-item="isSelectedLabel(labelTitle(label))"
        @click.prevent="$emit('select-label', label)"
      >
        <span
          :style="{ backgroundColor: label.color }"
          class="gl-display-inline-block dropdown-label-box"
        >
        </span>
        {{ labelTitle(label) }}
      </gl-dropdown-item>
      <div v-show="loading" class="gl-text-center">
        <gl-loading-icon :inline="true" size="lg" />
      </div>
      <div v-show="noMatchingLabels" class="gl-text-secondary">
        {{ __('No matching labels') }}
      </div>
    </div>
  </gl-dropdown>
</template>
