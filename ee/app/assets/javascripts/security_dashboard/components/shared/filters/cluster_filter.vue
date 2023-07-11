<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import getClusterAgentsQuery from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import { createAlert } from '~/alert';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

export default {
  components: {
    GlCollapsibleListbox,
    QuerystringSync,
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
          value: c.name,
          text: c.name,
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
    toggleText() {
      const options = this.clusterAgents?.filter(({ value }) => this.selected.includes(value));
      return getSelectedOptionsText({
        options,
        selected: this.selected,
        placeholder: this.$options.i18n.allItemsText,
      });
    },
    isLoading() {
      return this.$apollo.queries.clusterAgents.loading;
    },
    items() {
      return [
        {
          text: this.$options.i18n.allItemsText,
          value: ALL_ID,
        },
        ...this.clusterAgents,
      ];
    },
    selectedItems() {
      return this.selected.length ? this.selected : [ALL_ID];
    },
    clusterAgentIds() {
      return this.clusterAgents
        .filter(({ value }) => this.selected.includes(value))
        .map(({ gid }) => gid);
    },
  },
  watch: {
    clusterAgentIds: {
      immediate: true,
      handler() {
        this.$emit('filter-changed', { clusterAgentId: this.clusterAgentIds });
      },
    },
  },
  methods: {
    updateSelected(selected) {
      if (selected?.at(-1) === ALL_ID) {
        this.selected = [];
      } else {
        this.selected = selected.filter((value) => value !== ALL_ID);
      }
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
    <gl-collapsible-listbox
      :selected="selectedItems"
      :items="items"
      :toggle-text="toggleText"
      :header-text="$options.i18n.label"
      :loading="isLoading"
      multiple
      block
      @select="updateSelected"
    />
  </div>
</template>
