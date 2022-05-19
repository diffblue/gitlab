<script>
import { isEmpty } from 'lodash';
import { GlButton, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import dastProfilesSidebarMixin from './dast_profiles_sidebar_mixin';

export default {
  i18n: {
    scanSidebarHeader: s__('OnDemandScans|%{scannerType} profile library'),
    scanCreateSidebarHeader: s__('OnDemandScans|New %{scannerType} profile'),
    scanEditSidebarHeader: s__('OnDemandScans|Edit %{scannerType} profile'),
    scanSidebarHeaderButton: s__('OnDemandScans|New profile'),
  },
  name: 'DastProfilesSidebarHeader',
  components: {
    GlButton,
    GlSprintf,
  },
  mixins: [dastProfilesSidebarMixin()],
  props: {
    isEditingMode: {
      type: Boolean,
      required: false,
      default: true,
    },
    showNewProfileButton: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    sidebarHeader() {
      return capitalizeFirstCharacter(this.profileType);
    },
    editingModeHeader() {
      return !isEmpty(this.profile)
        ? this.$options.i18n.scanEditSidebarHeader
        : this.$options.i18n.scanCreateSidebarHeader;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-w-full gl-align-items-center gl-justify-content-space-between">
    <h4 data-testid="sidebar-header" class="sidebar-header gl-font-size-h2 gl-my-0 gl-mr-3">
      <gl-sprintf v-if="!isEditingMode" :message="$options.i18n.scanSidebarHeader">
        <template #scannerType>
          <span>{{ sidebarHeader }}</span>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else :message="editingModeHeader">
        <template #scannerType>
          <span>{{ profileType }}</span>
        </template>
      </gl-sprintf>
    </h4>
    <gl-button
      v-if="showNewProfileButton"
      class="gl-mr-4"
      variant="confirm"
      category="primary"
      size="small"
      data-testid="new-profile-button"
      @click="$emit('click')"
    >
      {{ $options.i18n.scanSidebarHeaderButton }}
    </gl-button>
  </div>
</template>

<style>
.gl-drawer-title {
  margin-left: -12px;
  margin-right: -12px;
}
</style>
