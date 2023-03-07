<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { OPTIONS_NONE_ANY } from '../constants';
import searchEpicsQuery from '../queries/search_epics.query.graphql';

export default {
  prefix: '&',
  separator: '::',
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      epics: this.config.initialEpics || [],
      loading: false,
    };
  },
  computed: {
    idProperty() {
      return this.config.idProperty || 'iid';
    },
    currentValue() {
      const epicIid = Number(this.value.data);
      if (epicIid) {
        return epicIid;
      }
      return this.value.data;
    },
    defaultEpics() {
      return this.config.defaultEpics || OPTIONS_NONE_ANY;
    },
  },
  methods: {
    fetchEpics(search = '') {
      return this.$apollo
        .query({
          query: searchEpicsQuery,
          variables: { fullPath: this.config.fullPath, search },
        })
        .then(({ data }) => data.group?.epics.nodes);
    },
    fetchEpicsBySearchTerm(search) {
      this.loading = true;
      this.fetchEpics(search)
        .then((response) => {
          this.epics = Array.isArray(response) ? response : response?.data;
        })
        .catch(() => createAlert({ message: __('There was a problem fetching epics.') }))
        .finally(() => {
          this.loading = false;
        });
    },
    getActiveEpic(epics, data) {
      if (data && epics.length) {
        return epics.find((epic) => this.getValue(epic) === data);
      }
      return undefined;
    },
    getValue(epic) {
      return this.getEpicIdProperty(epic).toString();
    },
    displayValue(epic) {
      return `${this.$options.prefix}${this.getEpicIdProperty(epic)}${this.$options.separator}${
        epic?.title
      }`;
    },
    getEpicIdProperty(epic) {
      return getIdFromGraphQLId(epic[this.idProperty]);
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="loading"
    :suggestions="epics"
    :get-active-token-value="getActiveEpic"
    :default-suggestions="defaultEpics"
    search-by="title"
    v-bind="$attrs"
    @fetch-suggestions="fetchEpicsBySearchTerm"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? displayValue(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="epic in suggestions"
        :key="epic.id"
        :value="getValue(epic)"
      >
        {{ epic.title }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
