<script>
import { GlDropdown, GlTruncate, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { xor } from 'lodash';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import agentImagesQuery from 'ee/security_dashboard/graphql/queries/agent_images.query.graphql';
import projectImagesQuery from 'ee/security_dashboard/graphql/queries/project_images.query.graphql';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import FilterItem from './filter_item.vue';
import QuerystringSync from './querystring_sync.vue';
import DropdownButtonText from './dropdown_button_text.vue';
import { ALL_ID } from './constants';

export default {
  components: {
    FilterItem,
    GlDropdown,
    GlTruncate,
    QuerystringSync,
    DropdownButtonText,
  },
  directives: { GlTooltip },
  apollo: {
    images: {
      query() {
        return this.isAgentDashboard ? agentImagesQuery : projectImagesQuery;
      },
      variables() {
        return {
          agentName: this.agentName,
          projectPath: this.projectFullPath || this.fullPath,
        };
      },
      update(data) {
        const vulnerabilityImages = this.isAgentDashboard
          ? data.project?.clusterAgent?.vulnerabilityImages
          : data.project?.vulnerabilityImages;

        return vulnerabilityImages.nodes.map(({ name }) => name);
      },
      error() {
        createAlert({ message: this.$options.i18n.loadingError });
      },
    },
  },
  inject: {
    agentName: { default: '' },
    dashboardType: { default: DASHBOARD_TYPES.PROJECT },
    fullPath: { default: '' },
    projectFullPath: { default: '' },
  },
  data: () => ({
    images: [],
    selected: [],
  }),
  computed: {
    isAgentDashboard() {
      return this.dashboardType === DASHBOARD_TYPES.PROJECT && Boolean(this.agentName);
    },
    selectedItemNames() {
      // Return the selected items, or all items if nothing is selected.
      return this.selected.length ? this.selected : [this.$options.i18n.allItemsText];
    },
    isLoading() {
      return this.$apollo.queries.images.loading;
    },
  },
  watch: {
    selected() {
      this.$emit('filter-changed', { image: this.selected });
    },
  },
  methods: {
    deselectAll() {
      this.selected = [];
    },
    toggleSelected(id) {
      this.selected = xor(this.selected, [id]);
    },
  },
  i18n: {
    label: s__('SecurityReports|Image'),
    allItemsText: s__('SecurityReports|All images'),
    loadingError: s__('SecurityOrchestration|Failed to load images.'),
  },
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="image" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-dropdown
      :header-text="$options.i18n.label"
      :loading="isLoading"
      block
      toggle-class="gl-mb-0"
    >
      <template #button-text>
        <dropdown-button-text :items="selectedItemNames" :name="$options.i18n.label" />
      </template>

      <filter-item
        :is-checked="!selected.length"
        :text="$options.i18n.allItemsText"
        :data-testid="$options.ALL_ID"
        @click="deselectAll"
      />

      <filter-item
        v-for="image in images"
        :key="image"
        :tooltip="image"
        :data-testid="image"
        :is-checked="selected.includes(image)"
        @click="toggleSelected(image)"
      >
        <!-- Empty title to prevent the native browser tooltip from showing at the same time as our own tooltip -->
        <gl-truncate position="middle" :text="image" title="" />
      </filter-item>
    </gl-dropdown>
  </div>
</template>
