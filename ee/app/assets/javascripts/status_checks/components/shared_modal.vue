<script>
import { GlModal, GlModalDirective } from '@gitlab/ui';
import { mapState } from 'vuex';
import { __ } from '~/locale';
import { ALL_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';
import { modalPrimaryActionProps } from '../utils';
import StatusCheckForm from './form.vue';

const i18n = { cancelButton: __('Cancel') };

export default {
  components: {
    GlModal,
    StatusCheckForm,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    action: {
      type: Function,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    statusCheck: {
      type: Object,
      required: false,
      default: undefined,
    },
    title: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      serverValidationErrors: [],
      submitting: false,
    };
  },
  computed: {
    ...mapState({
      projectId: ({ settings }) => settings.projectId,
    }),
    primaryActionProps() {
      return modalPrimaryActionProps(this.title, this.submitting);
    },
  },
  methods: {
    async submit() {
      this.$refs.form.submit();
    },
    async handleFormSubmit(formData) {
      this.submitting = true;

      const { branches, name, url } = formData;

      try {
        await this.action({
          externalUrl: url,
          id: this.statusCheck?.id,
          name,
          protectedBranchIds: branches.map((x) => x.id).filter((x) => x !== ALL_BRANCHES.id),
        });

        this.$refs.modal.hide();
      } catch (failureResponse) {
        this.serverValidationErrors = failureResponse?.response?.data?.message || [];
      }

      this.submitting = false;
    },
    show() {
      this.$refs.modal.show();
    },
    resetModal() {
      this.serverValidationErrors = [];
    },
  },
  cancelActionProps: {
    text: i18n.cancelButton,
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :title="title"
    :action-primary="primaryActionProps"
    :action-cancel="$options.cancelActionProps"
    size="sm"
    @ok.prevent="submit"
    @hidden="resetModal"
  >
    <status-check-form
      ref="form"
      :project-id="projectId"
      :server-validation-errors="serverValidationErrors"
      :status-check="statusCheck"
      @submit="handleFormSubmit"
    />
  </gl-modal>
</template>
