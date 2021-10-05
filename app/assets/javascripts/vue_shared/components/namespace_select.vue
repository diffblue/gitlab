<script>
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlSearchBoxByType } from '@gitlab/ui';

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
    fullWidth: {
      type: Boolean,
      required: false,
      default: false,
    },
    dropdownText: {
      type: String,
      required: true,
    },
    data: {
      type: Object,
      required: true,
    },
    dropdownClasses: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      searchTerm: '',
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
  },
  methods: {
    handleSelect(item) {
      this.$emit('select', item);
    },
  },
};
</script>
<template>
  <gl-dropdown :text="dropdownText" :block="fullWidth">
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
