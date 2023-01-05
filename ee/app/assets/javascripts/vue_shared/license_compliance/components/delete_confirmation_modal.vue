<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import { s__, __ } from '~/locale';

export default {
  name: 'LicenseDeleteConfirmationModal',
  components: { GlModal, GlSprintf },
  computed: {
    ...mapState(LICENSE_MANAGEMENT, ['currentLicenseInModal']),
  },
  methods: {
    ...mapActions(LICENSE_MANAGEMENT, ['resetLicenseInModal', 'deleteLicense']),
  },
  modal: {
    title: s__('LicenseCompliance|Remove license?'),
    actionPrimary: {
      text: s__('LicenseCompliance|Remove license'),
      attributes: { variant: 'danger' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
};
</script>
<template>
  <gl-modal
    modal-id="modal-license-delete-confirmation"
    :title="$options.modal.title"
    :action-primary="$options.modal.actionPrimary"
    :action-cancel="$options.modal.actionCancel"
    @primary="deleteLicense(currentLicenseInModal)"
    @cancel="resetLicenseInModal"
  >
    <gl-sprintf
      v-if="currentLicenseInModal"
      :message="
        s__('LicenseCompliance|You are about to remove the license, %{name}, from this project.')
      "
    >
      <template #name>
        <strong>{{ currentLicenseInModal.name }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
