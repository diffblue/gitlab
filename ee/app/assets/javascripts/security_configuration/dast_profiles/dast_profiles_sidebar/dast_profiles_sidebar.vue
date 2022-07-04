<script>
import { isEmpty } from 'lodash';
import { GlDrawer, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { SCANNER_TYPE, SIDEBAR_VIEW_MODE } from 'ee/on_demand_scans/constants';
import { REFERRAL } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import DastProfilesLoader from 'ee/security_configuration/dast_profiles/components/dast_profiles_loader.vue';
import { getContentWrapperHeight } from 'ee/security_orchestration/utils';
import DastProfilesSidebarHeader from './dast_profiles_sidebar_header.vue';
import DastProfilesSidebarEmptyState from './dast_profiles_sidebar_empty_state.vue';
import DastProfilesSidebarForm from './dast_profiles_sidebar_form.vue';
import DastProfilesSidebarList from './dast_profiles_sidebar_list.vue';

/**
 *                   Referral
 *                  /        \
 *            Parent          Self
 *           /      \        /    \
 *        New      Edit     New     Edit
 *      /   \      /  \     / \     / \
 *     C     R    C    C   C   R   R   R
 *
 * New profile or edit existing can be called both from component and parent
 * When form is opened it can be closed either by submit or cancel
 * This tree represent behaviour of a drawer.
 * Bottom level left subtree is after submit right subtree is after cancel
 *
 * For example Opened from parent -> new profile -> close after submit or reopen after cancel
 *
 * C-close
 * R-reopen
 */

export default {
  SIDEBAR_VIEW_MODE,
  i18n: {
    footerLinkText: s__('DastProfiles|Manage %{profileType} profiles'),
  },
  components: {
    GlDrawer,
    GlLink,
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
    selectedProfileId: {
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
    sidebarViewMode: {
      type: String,
      required: false,
      default: SIDEBAR_VIEW_MODE.READING_MODE,
    },
    libraryLink: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      profileForEditing: {},
      referral: REFERRAL.SELF,
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
      return !this.hasProfiles && !this.isEditingMode;
    },
    isReadingMode() {
      return this.hasProfiles && this.sidebarViewMode === SIDEBAR_VIEW_MODE.READING_MODE;
    },
    isEditingMode() {
      return this.sidebarViewMode === SIDEBAR_VIEW_MODE.EDITING_MODE;
    },
    footerLinkText() {
      return sprintf(this.$options.i18n.footerLinkText, {
        profileType: this.profileType,
      });
    },
    showFooter() {
      return Boolean(this.libraryLink) && !this.isEditingMode;
    },
  },
  /**
   * Only if activeProfile is passed from parent
   * editing mode should be immediately activated
   */
  watch: {
    activeProfile(newVal) {
      if (!isEmpty(newVal)) {
        this.referral = REFERRAL.PARENT;
        this.enableEditingMode({
          profile: this.activeProfile,
          mode: SIDEBAR_VIEW_MODE.EDITING_MODE,
        });
      }
    },
  },
  methods: {
    resetAndEmitCloseEvent() {
      this.resetEditingMode();
      this.$emit('close-drawer');
    },
    resetEditingMode() {
      this.profileForEditing = {};
      this.referral = REFERRAL.SELF;
    },
    enableEditingMode({ profile = {}, mode }) {
      this.profileForEditing = profile;
      this.$emit('reopen-drawer', { profileType: this.profileType, mode });
    },
    /**
     * reopen even for closing editing layer
     * and opening drawer with profiles list
     */
    cancelEditingMode() {
      const event = this.referral === REFERRAL.PARENT ? 'close-drawer' : 'reopen-drawer';

      this.$emit(event, { profileType: this.profileType, mode: SIDEBAR_VIEW_MODE.READING_MODE });
      this.resetEditingMode();
    },
    profileCreated(profile) {
      this.$emit('profile-submitted', { profile, profileType: this.profileType });
      this.$emit('close-drawer', {
        profileType: this.profileType,
        mode: SIDEBAR_VIEW_MODE.READING_MODE,
      });
      this.resetEditingMode();
    },
    profileEdited(profile) {
      this.$emit('profile-submitted', { profile, profileType: this.profileType });

      const secondaryEvent = this.referral === REFERRAL.PARENT ? 'close-drawer' : 'reopen-drawer';
      this.$emit(secondaryEvent, {
        profileType: this.profileType,
        mode: SIDEBAR_VIEW_MODE.READING_MODE,
      });
      this.resetEditingMode();
    },
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :header-sticky="true"
    :open="isOpen"
    :z-index="10"
    @close="resetAndEmitCloseEvent"
  >
    <template #title>
      <dast-profiles-sidebar-header
        :show-new-profile-button="isReadingMode"
        :is-editing-mode="isEditingMode"
        :profile-type="profileType"
        :profile="profileForEditing"
        @click="enableEditingMode({ mode: $options.SIDEBAR_VIEW_MODE.EDITING_MODE })"
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
          @click="enableEditingMode({ mode: $options.SIDEBAR_VIEW_MODE.EDITING_MODE })"
        />

        <!-- Create or Edit profile - editing mode -->
        <dast-profiles-sidebar-form
          v-if="isEditingMode"
          :profile="profileForEditing"
          :profile-type="profileType"
          @cancel="cancelEditingMode"
          @created="profileCreated"
          @edited="profileEdited"
        />

        <!-- Profile list - reading mode -->
        <DastProfilesSidebarList
          v-if="isReadingMode"
          class="gl-p-1!"
          :profiles="profiles"
          :profile-id-in-use="profileIdInUse"
          :selected-profile-id="selectedProfileId"
          :profile-type="profileType"
          @edit="
            enableEditingMode({ profile: $event, mode: $options.SIDEBAR_VIEW_MODE.EDITING_MODE })
          "
          v-on="$listeners"
        />
      </template>
    </template>
    <template #footer>
      <div v-if="showFooter" class="gl-w-full gl-text-center">
        <gl-link :href="libraryLink">
          {{ footerLinkText }}
        </gl-link>
      </div>
    </template>
  </gl-drawer>
</template>
