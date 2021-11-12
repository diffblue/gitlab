<script>
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlSearchBoxByType } from '@gitlab/ui';
import { __ } from '~/locale';

export const i18n = {
  DEFAULT_TEXT: __('Select a namespace'),
};

const filterByName = (data, searchTerm = '') =>
  data.filter((d) => d.humanName.toLowerCase().includes(searchTerm));

export default {
  name: 'NamespaceSelect',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    fullWidth: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedNamespace: null,
    };
  },
  computed: {
    hasUserNamespaces() {
      return this.data.user.length;
    },
    hasGroupNamespaces() {
      return this.data.group.length;
    },
    filteredGroupNamespaces() {
      if (!this.hasGroupNamespaces) return [];
      return filterByName(this.data.group, this.searchTerm);
    },
    filteredUserNamespaces() {
      if (!this.hasUserNamespaces) return [];
      return filterByName(this.data.user, this.searchTerm);
    },
    selectedNamespaceText() {
      return this.selectedNamespace?.humanName || this.$options.i18n.DEFAULT_TEXT;
    },
  },
  methods: {
    handleSelect(item) {
      this.selectedNamespace = item;
      this.$emit('select', item);
    },
  },
  i18n,
};
</script>
<template>
  <gl-dropdown :text="selectedNamespaceText" :block="fullWidth">
    <template #header>
      <gl-search-box-by-type v-model.trim="searchTerm" />
    </template>
    <template v-if="hasGroupNamespaces">
      <gl-dropdown-section-header>{{ __('Groups') }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="item in filteredGroupNamespaces"
        :key="item.id"
        @click="handleSelect(item)"
        >{{ item.humanName }}</gl-dropdown-item
      >
    </template>
    <template v-if="hasUserNamespaces">
      <gl-dropdown-section-header>{{ __('Users') }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="item in filteredUserNamespaces"
        :key="item.id"
        @click="handleSelect(item)"
        >{{ item.humanName }}</gl-dropdown-item
      >
    </template>
  </gl-dropdown>
</template>
