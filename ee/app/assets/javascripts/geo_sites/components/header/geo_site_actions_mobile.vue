<script>
import { GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __ } from '~/locale';

export default {
  name: 'GeoSiteActionsMobile',
  i18n: {
    editButtonLabel: __('Edit'),
    removeButtonLabel: __('Remove'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['canRemoveSite']),
    dropdownRemoveClass() {
      return this.canRemoveSite(this.site.id) ? 'gl-text-red-500' : 'gl-text-gray-400';
    },
  },
};
</script>

<template>
  <gl-dropdown toggle-class="gl-shadow-none! gl-bg-transparent! gl-p-3!" right>
    <template #button-content>
      <gl-icon name="ellipsis_h" />
    </template>
    <gl-dropdown-item :href="site.webEditUrl">{{ $options.i18n.editButtonLabel }}</gl-dropdown-item>
    <gl-dropdown-item
      :disabled="!canRemoveSite(site.id)"
      data-testid="geo-mobile-remove-action"
      @click="$emit('remove')"
    >
      <span :class="dropdownRemoveClass">{{ $options.i18n.removeButtonLabel }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
