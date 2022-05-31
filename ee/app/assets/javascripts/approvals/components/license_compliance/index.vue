<script>
import { GlButton, GlIcon, GlLink, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { APPROVALS, APPROVALS_MODAL } from 'ee/approvals/stores/modules/license_compliance';
import { s__ } from '~/locale';
import ModalLicenseCompliance from './modal.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    ModalLicenseCompliance,
  },
  computed: {
    ...mapState({
      isLoading: (state) => state[APPROVALS].isLoading,
      rules: (state) => state[APPROVALS].rules,
      documentationPath: ({ settings }) => settings.approvalsDocumentationPath,
      licenseCheckRuleName: ({ settings }) => settings.lockedApprovalsRuleName,
    }),
    licenseCheckRule() {
      return this.rules?.find(({ name }) => name === this.licenseCheckRuleName);
    },
    hasLicenseCheckRule() {
      const { licenseCheckRule: { approvalsRequired = 0 } = {} } = this;
      return approvalsRequired > 0;
    },
    licenseCheckStatusText() {
      return this.hasLicenseCheckRule
        ? s__('LicenseCompliance|%{docLinkStart}License Approvals%{docLinkEnd} are active')
        : s__('LicenseCompliance|%{docLinkStart}License Approvals%{docLinkEnd} are inactive');
    },
  },
  created() {
    this.fetchRules();
  },
  methods: {
    ...mapActions(['fetchRules']),
    ...mapActions({
      openModal(dispatch, licenseCheckRule) {
        dispatch(`${APPROVALS_MODAL}/open`, licenseCheckRule);
      },
    }),
  },
};
</script>
<template>
  <span class="gl-display-inline-flex gl-align-items-center">
    <gl-button :loading="isLoading" @click="openModal(licenseCheckRule)"
      >{{ s__('LicenseCompliance|Update approvals') }}
    </gl-button>
    <span data-testid="licenseCheckStatus" class="gl-ml-3">
      <gl-skeleton-loader v-if="isLoading" :aria-label="__('loading')" :lines="1" />
      <span v-else class="gl-m-0 gl-font-weight-normal">
        <gl-icon name="information-o" :size="12" class="gl-text-blue-600" />
        <gl-sprintf :message="licenseCheckStatusText">
          <template #docLink="{ content }">
            <gl-link :href="documentationPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </span>
    <modal-license-compliance />
  </span>
</template>
