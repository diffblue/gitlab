<script>
import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlLoadingIcon,
  GlAvatar,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { sprintf, s__, __ } from '~/locale';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlLoadingIcon,
    GlAvatar,
  },
  inheritAttrs: false,
  props: {
    value: {
      type: Object,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
    fetchItem: {
      type: Function,
      required: true,
    },
    fetchSuggestions: {
      type: Function,
      required: true,
    },
    getItemName: {
      type: Function,
      required: true,
    },
    getSuggestionValue: {
      type: Function,
      required: true,
    },
    findActiveItem: {
      type: Function,
      required: true,
    },
    isValidIdentifier: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      activeItem: null,
      viewLoading: false,
      suggestionsLoading: false,
      suggestions: [],
    };
  },
  computed: {
    activeItemName() {
      return this.activeItem ? this.getItemName(this.activeItem) : null;
    },
    debouncedLoadSuggestions() {
      return debounce(this.loadSuggestions, 500);
    },
    hasSuggestions() {
      return this.suggestions?.length > 0;
    },
    lowerCaseType() {
      return this.config.type.replace('_', ' ').trim().toLowerCase();
    },
    noSuggestionsString() {
      return sprintf(s__('AuditLogs|No matching %{type} found.'), { type: this.lowerCaseType });
    },
  },
  watch: {
    // eslint-disable-next-line func-names
    'value.data': function (term) {
      this.debouncedLoadSuggestions(term);
    },
    active() {
      const { data: input } = this.value;
      if (this.isValidIdentifier(input)) {
        this.activeItem = this.findActiveItem(this.suggestions, input);
      }
    },
  },
  mounted() {
    const { data: id } = this.value;
    if (this.isValidIdentifier(id)) {
      this.loadView(id);
    } else {
      this.loadSuggestions();
    }
  },
  methods: {
    getAvatarString(name) {
      return sprintf(__("%{name}'s avatar"), { name });
    },
    onApiError({ response: { status } }) {
      const type = this.lowerCaseType;
      let message;
      if (status === HTTP_STATUS_NOT_FOUND) {
        message = s__('AuditLogs|Failed to find %{type}. Please search for another %{type}.');
      } else {
        message = s__('AuditLogs|Failed to find %{type}. Please try again.');
      }
      createAlert({
        message: sprintf(message, { type }),
      });
    },
    loadView(id) {
      this.viewLoading = true;
      return this.fetchItem(id)
        .then((data) => {
          if (data) {
            this.activeItem = data;
            this.suggestions.push(data);
          }
        })
        .catch(this.onApiError)
        .finally(() => {
          this.viewLoading = false;
        });
    },
    loadSuggestions(term) {
      this.suggestionsLoading = true;
      return this.fetchSuggestions(term)
        .then((data) => {
          this.suggestions = data;
        })
        .catch(this.onApiError)
        .finally(() => {
          this.suggestionsLoading = false;
        });
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    v-bind="{ ...$props, ...$attrs }"
    :operators="config.operators"
    v-on="$listeners"
  >
    <template #view>
      <gl-loading-icon v-if="viewLoading" size="sm" class="gl-mr-2" />
      <template v-else-if="activeItem">
        <gl-avatar
          :size="16"
          :src="activeItem.avatar_url"
          :entity-name="activeItemName"
          :entity-id="activeItem.id"
          :alt="getAvatarString(activeItem.name)"
          class="gl-mr-2"
          data-testid="audit-filter-item-avatar"
        />
        {{ activeItemName }}
      </template>
    </template>
    <template #suggestions>
      <template v-if="suggestionsLoading">
        <gl-loading-icon size="sm" />
      </template>
      <template v-else-if="hasSuggestions">
        <gl-filtered-search-suggestion
          v-for="item in suggestions"
          :key="item.id"
          :value="getSuggestionValue(item)"
          data-testid="audit-filter-suggestion"
        >
          <div class="d-flex">
            <gl-avatar
              :size="32"
              :src="item.avatar_url"
              :entity-id="item.id"
              :entity-name="item.name"
              :alt="getAvatarString(item.name)"
            />
            <div>
              <slot name="suggestion" :item="item"></slot>
            </div>
          </div>
        </gl-filtered-search-suggestion>
      </template>
      <span v-else class="dropdown-item">{{ noSuggestionsString }}</span>
    </template>
  </gl-filtered-search-token>
</template>
