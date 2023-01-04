<script>
import { isEmpty } from 'lodash';
import { GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import dastProfilesDrawerMixin from './dast_profiles_drawer_mixin';

export default {
  i18n: {
    scanDrawerHeader: s__('OnDemandScans|%{profileType} profile library'),
    scanCreateDrawerHeader: s__('OnDemandScans|New %{profileType} profile'),
    scanEditDrawerHeader: s__('OnDemandScans|Edit %{profileType} profile'),
    scanDrawerHeaderButton: s__('OnDemandScans|New profile'),
  },
  name: 'DastProfilesDrawerHeader',
  components: {
    GlButton,
  },
  mixins: [dastProfilesDrawerMixin()],
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
    drawerHeader() {
      return sprintf(this.$options.i18n.scanDrawerHeader, {
        profileType: capitalizeFirstCharacter(this.profileType),
      });
    },
    editingModeHeader() {
      const header = !isEmpty(this.profile)
        ? this.$options.i18n.scanEditDrawerHeader
        : this.$options.i18n.scanCreateDrawerHeader;

      return sprintf(header, { profileType: this.profileType });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-w-full gl-align-items-center gl-justify-content-space-between">
    <h4 data-testid="drawer-header" class="gl-font-size-h2 gl-my-0 gl-mr-3">
      <template v-if="!isEditingMode">
        {{ drawerHeader }}
      </template>
      <template v-else>
        {{ editingModeHeader }}
      </template>
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
      {{ $options.i18n.scanDrawerHeaderButton }}
    </gl-button>
  </div>
</template>
