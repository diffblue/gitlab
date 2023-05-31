<script>
import { isEmpty } from 'lodash';
import { GlDrawer, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { DRAWER_VIEW_MODE } from 'ee/on_demand_scans/constants';
import DastProfilesLoader from 'ee/security_configuration/dast_profiles/components/dast_profiles_loader.vue';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import dastProfileConfiguratorMixin from 'ee/security_configuration/dast_profiles/dast_profiles_configurator_mixin';
import DastProfilesDrawerHeader from './dast_profiles_drawer_header.vue';
import DastProfilesDrawerEmptyState from './dast_profiles_drawer_empty_state.vue';
import DastProfilesDrawerForm from './dast_profiles_drawer_form.vue';
import DastProfilesDrawerList from './dast_profiles_drawer_list.vue';

export default {
  DRAWER_VIEW_MODE,
  DRAWER_Z_INDEX,
  i18n: {
    footerLinkText: s__('DastProfiles|Manage %{profileType} profiles'),
  },
  components: {
    GlDrawer,
    GlLink,
    DastProfilesLoader,
    DastProfilesDrawerHeader,
    DastProfilesDrawerEmptyState,
    DastProfilesDrawerForm,
    DastProfilesDrawerList,
  },
  mixins: [dastProfileConfiguratorMixin()],
  props: {
    open: {
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
    libraryLink: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      profileForEditing: {},
      sharedData: {},
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    hasProfiles() {
      return this.profiles.length > 0;
    },
    isEmptyStateMode() {
      return !this.hasProfiles && !this.isEditingMode;
    },
    isReadingMode() {
      return this.hasProfiles && this.drawerViewMode === DRAWER_VIEW_MODE.READING_MODE;
    },
    isEditingMode() {
      return this.drawerViewMode === DRAWER_VIEW_MODE.EDITING_MODE;
    },
    footerLinkText() {
      return sprintf(this.$options.i18n.footerLinkText, {
        profileType: this.profileType,
      });
    },
    showFooter() {
      return Boolean(this.libraryLink) && !this.isEditingMode;
    },
    isProfileInUse() {
      return this.profileForEditing.id === this.profileIdInUse;
    },
  },
  /**
   * Only if activeProfile is passed from parent
   * editing mode should be immediately activated
   */
  watch: {
    activeProfile(newVal) {
      if (!isEmpty(newVal)) {
        this.profileForEditing = this.activeProfile;
      }
    },
  },
  methods: {
    async resetAndEmitCloseEvent() {
      if (this.sharedData.formTouched) {
        await this.toggleModal({ showModal: true });
        await this.setResetAndClose({ resetAndClose: true });

        return;
      }

      this.resetEditingMode();
      await this.resetHistory();
      this.$emit('close-drawer');
    },
    resetEditingMode() {
      this.profileForEditing = {};
    },
    enableEditingMode({ profile = {}, mode }) {
      this.profileForEditing = profile;

      this.goForward({ profileType: this.profileType, mode });
      this.$emit('reopen-drawer', { profileType: this.profileType, mode });
    },
    /**
     * reopen even for closing editing layer
     * and opening drawer with profiles list
     */
    async cancelEditingMode() {
      if (this.sharedData.resetAndClose) {
        await this.resetAndEmitCloseEvent();
        this.setResetAndClose({ resetAndClose: false });
      }

      await this.goBack();

      if (this.hasCachedPayload) {
        await this.goFirstStep(this.cachedPayload);
      }

      this.$emit(this.eventName, { profileType: this.profileType, mode: this.drawerViewMode });
      await this.setCachedPayload(undefined);
    },
    async profileCreated(profile) {
      this.$emit('profile-submitted', { profile, profileType: this.profileType });

      await this.resetHistory();
      this.$emit(this.eventName, {
        profileType: this.profileType,
        mode: DRAWER_VIEW_MODE.READING_MODE,
      });

      await this.discardChanges();
      this.resetEditingMode();
    },
    async profileEdited(profile) {
      this.$emit('profile-submitted', { profile, profileType: this.profileType });

      await this.goBack();
      this.$emit(this.eventName, {
        profileType: this.profileType,
        mode: DRAWER_VIEW_MODE.READING_MODE,
      });

      await this.discardChanges();
      this.resetEditingMode();
    },
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :header-sticky="true"
    :open="open"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="resetAndEmitCloseEvent"
  >
    <template #title>
      <dast-profiles-drawer-header
        :show-new-profile-button="isReadingMode"
        :is-editing-mode="isEditingMode"
        :profile-type="profileType"
        :profile="profileForEditing"
        @click="enableEditingMode({ mode: $options.DRAWER_VIEW_MODE.EDITING_MODE })"
      />
    </template>
    <template #default>
      <template v-if="isLoading">
        <dast-profiles-loader />
      </template>
      <template v-else>
        <!-- Empty state -->
        <dast-profiles-drawer-empty-state
          v-if="isEmptyStateMode"
          class="gl-mt-11"
          :profile-type="profileType"
          @click="enableEditingMode({ mode: $options.DRAWER_VIEW_MODE.EDITING_MODE })"
        />

        <!-- Create or Edit profile - editing mode -->
        <dast-profiles-drawer-form
          v-if="isEditingMode"
          :profile="profileForEditing"
          :is-profile-in-use="isProfileInUse"
          :profile-type="profileType"
          @cancel="cancelEditingMode"
          @created="profileCreated"
          @edited="profileEdited"
        />

        <!-- Profile list - reading mode -->
        <dast-profiles-drawer-list
          v-if="isReadingMode"
          :profiles="profiles"
          :profile-id-in-use="profileIdInUse"
          :selected-profile-id="selectedProfileId"
          :profile-type="profileType"
          @edit="
            enableEditingMode({ profile: $event, mode: $options.DRAWER_VIEW_MODE.EDITING_MODE })
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
