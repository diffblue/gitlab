<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { HEALTH_SUGGESTIONS, DEFAULT_HEALTH_STATUSES } from '../constants';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    defaultHealth() {
      return this.config.defaultHealth || DEFAULT_HEALTH_STATUSES;
    },
  },
  methods: {
    capitalizeFirstCharacter,
  },
  HEALTH_SUGGESTIONS,
};
</script>

<template>
  <base-token
    :active="active"
    :config="config"
    :value="value"
    :default-suggestions="defaultHealth"
    :suggestions="$options.HEALTH_SUGGESTIONS"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{
        activeTokenValue
          ? activeTokenValue.title
          : capitalizeFirstCharacter(inputValue.toLowerCase())
      }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="health of suggestions"
        :key="health.value"
        :value="health.value"
      >
        {{ health.title }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
