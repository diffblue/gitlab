<script>
import { GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';

const i18n = {
  cancelButton: __('Cancel'),
  deleteError: s__('StatusCheck|An error occurred deleting the %{name} status check.'),
  primaryButton: s__('StatusCheck|Remove status check'),
  title: s__('StatusCheck|Remove status check?'),
  warningText: s__('StatusCheck|You are about to remove the %{name} status check.'),
};

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    statusCheck: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      submitting: false,
    };
  },
  computed: {
    ...mapState({
      projectId: ({ settings }) => settings.projectId,
    }),
    primaryActionProps() {
      return {
        text: i18n.primaryButton,
        attributes: { variant: 'danger', loading: this.submitting },
      };
    },
  },
  methods: {
    ...mapActions(['deleteStatusCheck']),
    async submit() {
      const { id, name } = this.statusCheck;

      this.submitting = true;

      try {
        await this.deleteStatusCheck(id);
      } catch (error) {
        createAlert({
          message: sprintf(i18n.deleteError, { name }),
          captureError: true,
          error,
        });
      }

      this.submitting = false;
      this.$refs.modal.hide();
    },
    show() {
      this.$refs.modal.show();
    },
  },
  modalId: 'status-checks-delete-modal',
  cancelActionProps: {
    text: i18n.cancelButton,
  },
  i18n,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    :title="$options.i18n.title"
    :action-primary="primaryActionProps"
    :action-cancel="$options.cancelActionProps"
    size="sm"
    @ok.prevent="submit"
  >
    <gl-sprintf :message="$options.i18n.warningText">
      <template #name>
        <strong>{{ statusCheck.name }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
