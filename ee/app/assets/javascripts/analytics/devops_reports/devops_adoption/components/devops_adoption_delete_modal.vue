<script>
import { GlModal, GlSprintf, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import {
  I18N_DELETE_MODAL_TITLE,
  I18N_DELETE_MODAL_CONFIRMATION_MESSAGE,
  I18N_DELETE_MODAL_CANCEL,
  I18N_DELETE_MODAL_CONFIRM,
  I18N_DELETE_MODAL_ERROR,
} from '../constants';
import disableDevopsAdoptionNamespaceMutation from '../graphql/mutations/disable_devops_adoption_namespace.mutation.graphql';

export default {
  name: 'DevopsAdoptionDeleteModal',
  components: { GlModal, GlSprintf, GlAlert },
  i18n: {
    title: I18N_DELETE_MODAL_TITLE,
    confirmationMessage: I18N_DELETE_MODAL_CONFIRMATION_MESSAGE,
    cancel: I18N_DELETE_MODAL_CANCEL,
    confirm: I18N_DELETE_MODAL_CONFIRM,
    error: I18N_DELETE_MODAL_ERROR,
  },
  props: {
    modalId: {
      required: true,
      type: String,
    },
    namespace: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      errors: [],
    };
  },
  computed: {
    cancelOptions() {
      return {
        text: this.$options.i18n.cancel,
        attributes: { disabled: this.loading },
      };
    },
    primaryOptions() {
      return {
        text: this.$options.i18n.confirm,
        attributes: {
          variant: 'danger',
          loading: this.loading,
        },
      };
    },
    displayError() {
      return this.errors[0];
    },
    displayName() {
      return this.namespace.namespace?.fullName;
    },
  },
  methods: {
    async deleteEnabledNamespace() {
      try {
        const {
          namespace: { id },
        } = this;

        this.loading = true;

        const {
          data: {
            disableDevopsAdoptionNamespace: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: disableDevopsAdoptionNamespaceMutation,
          variables: {
            id: [id],
          },
          update: () => {
            this.$emit('enabledNamespacesRemoved', [id]);
          },
        });

        if (errors.length) {
          this.errors = errors;
        } else {
          this.$refs.modal.hide();
        }
      } catch (error) {
        this.errors.push(this.$options.i18n.error);
        Sentry.captureException(error);
      } finally {
        this.loading = false;
      }
    },
    clearErrors() {
      this.errors = [];
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    size="sm"
    :action-primary="primaryOptions"
    :action-cancel="cancelOptions"
    @primary.prevent="deleteEnabledNamespace"
    @hide="$emit('trackModalOpenState', false)"
    @show="$emit('trackModalOpenState', true)"
  >
    <template #modal-title>{{ $options.i18n.title }}</template>
    <gl-alert v-if="errors.length" variant="danger" class="gl-mb-3" @dismiss="clearErrors">
      {{ displayError }}
    </gl-alert>
    <gl-sprintf :message="$options.i18n.confirmationMessage">
      <template #name
        ><strong>{{ displayName }}</strong></template
      >
    </gl-sprintf>
  </gl-modal>
</template>
