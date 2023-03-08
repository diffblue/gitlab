<script>
import { GlDropdown } from '@gitlab/ui';
import { xor } from 'lodash';
import { s__ } from '~/locale';
import getClusterAgentsQuery from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import { createAlert } from '~/alert';
import FilterItem from './filter_item.vue';
import QuerystringSync from './querystring_sync.vue';
import DropdownButtonText from './dropdown_button_text.vue';
import { ALL_ID } from './constants';

export default {
  components: {
    FilterItem,
    GlDropdown,
    QuerystringSync,
    DropdownButtonText,
  },
  apollo: {
    clusterAgents: {
      query: getClusterAgentsQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      update: (data) =>
        data.project?.clusterAgents?.nodes.map((c) => ({
          id: c.name,
          name: c.name,
          gid: c.id,
        })) || [],
      error() {
        createAlert({ message: this.$options.i18n.loadingError });
      },
    },
  },
  inject: ['projectFullPath'],
  data: () => ({
    clusterAgents: [],
    selected: [],
  }),
  computed: {
    selectedItemNames() {
      const options = this.clusterAgents?.filter(({ id }) => this.selected.includes(id));
      // Return the text for selected items, or all items if nothing is selected.
      return options.length ? options.map(({ name }) => name) : [this.$options.i18n.allItemsText];
    },
    isLoading() {
      return this.$apollo.queries.clusterAgents.loading;
    },
  },
  watch: {
    selected() {
      const gids = this.clusterAgents
        .filter(({ id }) => this.selected.includes(id))
        .map(({ gid }) => gid);

      this.$emit('filter-changed', { clusterAgentId: gids });
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
    label: s__('SecurityReports|Cluster'),
    allItemsText: s__('SecurityReports|All clusters'),
    loadingError: s__('SecurityOrchestration|Failed to load cluster agents.'),
  },
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="cluster" />
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
        v-for="{ id } in clusterAgents"
        :key="id"
        :data-testid="id"
        :is-checked="selected.includes(id)"
        :text="id"
        @click="toggleSelected(id)"
      />
    </gl-dropdown>
  </div>
</template>
