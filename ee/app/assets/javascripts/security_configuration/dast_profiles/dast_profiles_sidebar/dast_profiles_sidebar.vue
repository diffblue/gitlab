<script>
import { GlButton, GlDrawer, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { SCANNER_TYPE, SITE_TYPE } from 'ee/on_demand_scans/constants';
import DastScannerProfileForm from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/components/dast_scanner_profile_form.vue';
import DastSiteProfileForm from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_profile_form.vue';
import DastProfilesLoader from 'ee/security_configuration/dast_profiles/components/dast_profiles_loader.vue';
import { getContentWrapperHeight } from 'ee/threat_monitoring/utils';

export default {
  i18n: {
    emptyStateButton: s__('OnDemandScans|New %{scannerType} profile'),
    emptyStateContent: s__(
      'OnDemandScans|Start by creating a new profile. Profiles make it easy to save and reuse configuration details for GitLab’s security tools.',
    ),
    emptyStateHeader: s__('OnDemandScans|No %{scannerType} profiles found for DAST'),
    scanSidebarHeader: s__('OnDemandScans|%{scannerType} profile library'),
    scanSidebarHeaderButton: s__('OnDemandScans|New profile'),
  },
  components: {
    GlButton,
    GlDrawer,
    GlSprintf,
    DastScannerProfileForm,
    DastSiteProfileForm,
    DastProfilesLoader,
  },
  inject: ['projectPath'],
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
    isEmptyState() {
      return !this.hasProfiles && !this.editingMode;
    },
    isScannerType() {
      return this.profileType === SCANNER_TYPE;
    },
    isSiteType() {
      return this.profileType === SITE_TYPE;
    },
    isShowProfilesState() {
      return this.hasProfiles && !this.editingMode;
    },
    sidebarHeader() {
      return capitalizeFirstCharacter(this.profileType);
    },
  },
  methods: {
    closeDrawer() {
      this.editingMode = false;
      this.$emit('close-drawer');
    },
    enableEditingMode() {
      this.profileForEditing = {};
      this.editingMode = true;
    },
    enableEditScannerMode(profile) {
      this.profileForEditing = profile;
    },
    cancelEditingMode() {
      this.editingMode = false;
    },
    submitEditingMode() {
      this.editingMode = false;
      this.$emit('profile-submitted', this.profileType);
    },
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :open="isOpen"
    :z-index="10"
    @close="closeDrawer"
  >
    <template #title>
      <div class="gl-display-flex gl-w-full gl-align-items-center gl-justify-content-space-between">
        <h4 data-testid="sidebar-header" class="gl-font-size-h2 gl-my-0 gl-mr-3">
          <gl-sprintf :message="$options.i18n.scanSidebarHeader">
            <template #scannerType>
              <span>{{ sidebarHeader }}</span>
            </template>
          </gl-sprintf>
        </h4>
        <gl-button
          v-if="hasProfiles"
          class="gl-mr-4"
          variant="confirm"
          category="primary"
          size="small"
          data-testid="new-profile-button"
          @click="enableEditingMode"
        >
          {{ $options.i18n.scanSidebarHeaderButton }}
        </gl-button>
      </div>
    </template>
    <template #default>
      <template v-if="isLoading">
        <DastProfilesLoader />
      </template>
      <template v-else>
        <div
          v-if="isEmptyState"
          class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-mt-11"
        >
          <h5 class="gl-text-secondary gl-mt-0 gl-mb-2" data-testid="empty-state-header">
            <slot name="header">
              <gl-sprintf :message="$options.i18n.emptyStateHeader">
                <template #scannerType>
                  <span>{{ profileType }}</span>
                </template>
              </gl-sprintf>
            </slot>
          </h5>
          <span class="gl-text-gray-500 gl-text-center">
            {{ $options.i18n.emptyStateContent }}
          </span>
          <gl-button
            class="gl-mt-5"
            variant="confirm"
            category="primary"
            data-testid="new-empty-profile-button"
            @click="enableEditingMode"
          >
            <gl-sprintf :message="$options.i18n.emptyStateButton">
              <template #scannerType>
                <span>{{ profileType }}</span>
              </template>
            </gl-sprintf>
          </gl-button>
        </div>
        <transition name="gl-drawer">
          <div v-if="editingMode">
            <dast-scanner-profile-form
              v-if="isScannerType"
              :stacked="true"
              :profile="profileForEditing"
              :project-full-path="projectPath"
              @cancel="cancelEditingMode"
              @success="submitEditingMode"
            />
            <dast-site-profile-form
              v-else-if="isSiteType"
              :stacked="true"
              :profile="profileForEditing"
              :project-full-path="projectPath"
              @cancel="cancelEditingMode"
              @success="submitEditingMode"
            />
          </div>
        </transition>
        <slot v-if="isShowProfilesState" name="content"></slot>
      </template>
    </template>
  </gl-drawer>
</template>
