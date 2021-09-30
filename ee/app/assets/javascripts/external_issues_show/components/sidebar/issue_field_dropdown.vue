<script>
import { GlDropdown, GlDropdownItem, GlDropdownText, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlLoadingIcon,
  },
  props: {
    emptyText: {
      type: String,
      required: false,
      default: null,
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: true,
    },
    text: {
      type: String,
      required: false,
      default: null,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    noItems() {
      return this.items.length === 0;
    },
  },
  methods: {
    showDropdown() {
      this.$refs.dropdown.show();
    },
    selectItem(item) {
      this.$emit('issue-field-updated', item.title);
    },
  },
};
</script>

<template>
  <gl-dropdown ref="dropdown" :text="text" :header-text="title" block lazy>
    <div v-if="loading" class="gl-h-13">
      <gl-loading-icon size="md" />
    </div>
    <div v-else>
      <gl-dropdown-text v-if="noItems">{{ emptyText }}</gl-dropdown-text>
      <gl-dropdown-item v-for="item in items" :key="item.title" @click="selectItem(item)">
        {{ item.title }}
      </gl-dropdown-item>
    </div>
  </gl-dropdown>
</template>
