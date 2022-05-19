<script>
import { isEmpty } from 'lodash';
import { GlDrawer } from '@gitlab/ui';
import { SCANNER_TYPE } from 'ee/on_demand_scans/constants';
import DastProfilesLoader from 'ee/security_configuration/dast_profiles/components/dast_profiles_loader.vue';
import { getContentWrapperHeight } from 'ee/threat_monitoring/utils';
import DastProfilesSidebarHeader from './dast_profiles_sidebar_header.vue';
import DastProfilesSidebarEmptyState from './dast_profiles_sidebar_empty_state.vue';
import DastProfilesSidebarForm from './dast_profiles_sidebar_form.vue';
import DastProfilesSidebarList from './dast_profiles_sidebar_list.vue';

export default {
  components: {
    GlDrawer,
    DastProfilesLoader,
    DastProfilesSidebarHeader,
    DastProfilesSidebarEmptyState,
    DastProfilesSidebarForm,
    DastProfilesSidebarList,
  },
  props: {
    isOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    profiles: {
      type: Array,
      required: false,
      default: () => [],
    },
    profileIdInUse: {
      type: String,
      required: false,
      default: null,
    },
    /**
     * String type in case
     * there will be more types
     */
    profileType: {
      type: String,
      required: false,
      default: SCANNER_TYPE,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * There is an option to activate
     * editing mode from parent
     * This property is used for
     * passing profile for editing and
     * activating editing mode
     */
    activeProfile: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      editingMode: false,
      profileForEditing: {},
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight('.nav-sidebar');
    },
    hasProfiles() {
      return this.profiles.length > 0;
    },
    isEmptyStateMode() {
      return !this.hasProfiles && !this.editingMode;
    },
    isReadingMode() {
      return this.hasProfiles && !this.editingMode;
    },
    isEditingMode() {
      return this.editingMode;
    },
  },
  /**
   * Only if activeProfile is passed from parent
   * editing mode should be immediately activated
   */
  watch: {
    activeProfile(newVal) {
      if (!isEmpty(newVal)) {
        this.enableEditingMode(this.activeProfile);
      }
    },
  },
  methods: {
    enableEditingMode(profile) {
      this.editingMode = true;
      this.profileForEditing = profile;
      this.$emit('reopen-drawer', this.profileType);
    },
    /**
     * reopen even for closing editing layer
     * and opening drawer with profiles list
     */
    exitEditingModeWith(event) {
      this.editingMode = false;
      this.profileForEditing = {};
      this.$emit(event, this.profileType);
    },
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :open="isOpen"
    :z-index="10"
    @close="exitEditingModeWith('close-drawer')"
  >
    <template #title>
      <dast-profiles-sidebar-header
        :show-new-profile-button="isReadingMode"
        :is-editing-mode="isEditingMode"
        :profile-type="profileType"
        :profile="profileForEditing"
        @click="enableEditingMode({})"
      />
    </template>
    <template #default>
      <template v-if="isLoading">
        <DastProfilesLoader />
      </template>
      <template v-else>
        <!-- Empty state -->
        <dast-profiles-sidebar-empty-state
          v-if="isEmptyStateMode"
          class="gl-mt-11"
          :profile-type="profileType"
          @click="enableEditingMode({})"
        />

        <!-- Create or Edit profile - editing mode -->
        <dast-profiles-sidebar-form
          v-if="isEditingMode"
          :profile="profileForEditing"
          :profile-type="profileType"
          @cancel="exitEditingModeWith('reopen-drawer')"
          @success="exitEditingModeWith('profile-submitted')"
        />

        <!-- Profile list - reading mode -->
        <DastProfilesSidebarList
          v-if="isReadingMode"
          class="gl-p-1!"
          :profiles="profiles"
          :profile-id-in-use="profileIdInUse"
          :profile-type="profileType"
          @edit="enableEditingMode"
          v-on="$listeners"
        />
      </template>
    </template>
  </gl-drawer>
</template>
