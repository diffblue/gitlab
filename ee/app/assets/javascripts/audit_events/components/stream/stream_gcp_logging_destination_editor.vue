<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import * as Sentry from '@sentry/browser';
import { GlTooltipDirective as GlTooltip } from '@gitlab/ui/dist/directives/tooltip';
import { createAlert } from '~/alert';
import googleCloudLoggingConfigurationCreate from '../../graphql/mutations/create_gcp_logging_destination.mutation.graphql';
import googleCloudLoggingConfigurationUpdate from '../../graphql/mutations/update_gcp_logging_destination.mutation.graphql';
import {
  ADD_STREAM_EDITOR_I18N,
  AUDIT_STREAMS_NETWORK_ERRORS,
  DESTINATION_TYPE_GCP_LOGGING,
} from '../../constants';
import { addGcpLoggingAuditEventsStreamingDestination } from '../../graphql/cache_update';
import StreamDeleteModal from './stream_delete_modal.vue';

const { CREATING_ERROR, UPDATING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    StreamDeleteModal,
  },
  directives: {
    GlTooltip,
  },
  inject: ['groupPath'],
  props: {
    item: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      googleProjectIdName: '',
      logIdName: '',
      privateKey: '',
      clientEmail: '',
      errors: [],
      loading: false,
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      if (!this.googleProjectIdName || !this.logIdName || !this.privateKey || !this.clientEmail) {
        return true;
      }

      return this.hasNoChanges;
    },
    hasNoChanges() {
      const { googleProjectIdName, logIdName, privateKey, clientEmail } = this.item;

      return (
        googleProjectIdName === this.googleProjectIdName &&
        logIdName === this.logIdName &&
        privateKey === this.privateKey &&
        clientEmail === this.clientEmail
      );
    },
    isEditing() {
      return !isEmpty(this.item);
    },
    addButtonName() {
      return this.isEditing
        ? ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_NAME
        : ADD_STREAM_EDITOR_I18N.ADD_BUTTON_NAME;
    },
    addButtonText() {
      return this.isEditing
        ? ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_TEXT
        : ADD_STREAM_EDITOR_I18N.ADD_BUTTON_TEXT;
    },
  },
  mounted() {
    this.googleProjectIdName = this.item.googleProjectIdName;
    this.logIdName = this.item.logIdName;
    this.privateKey = this.item.privateKey;
    this.clientEmail = this.item.clientEmail;
  },
  methods: {
    onDeleting() {
      this.loading = true;
    },
    onDelete() {
      this.$emit('deleted', this.item.id);
      this.loading = false;
    },
    onError(error) {
      this.loading = false;
      createAlert({
        message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
        captureError: true,
        error,
      });
      this.$emit('error');
    },
    clearError(index) {
      this.errors.splice(index, 1);
    },
    async addDestination() {
      this.errors = [];
      this.loading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: googleCloudLoggingConfigurationCreate,
          variables: {
            id: this.item.id,
            fullPath: this.groupPath,
            googleProjectIdName: this.googleProjectIdName,
            clientEmail: this.clientEmail,
            privateKey: this.privateKey,
            logIdName: this.logIdName,
          },
          context: {
            isSingleRequest: true,
          },
          update(cache, { data: updateData }, args) {
            const errors = updateData?.googleCloudLoggingConfigurationCreate?.errors;
            if (errors.length) {
              return;
            }

            const newGcpLoggingDestination =
              updateData?.googleCloudLoggingConfigurationCreate?.googleCloudLoggingConfiguration;

            addGcpLoggingAuditEventsStreamingDestination({
              store: cache,
              fullPath: args.variables.fullPath,
              newDestination: newGcpLoggingDestination,
            });
          },
        });

        const { errors } = data.googleCloudLoggingConfigurationCreate;

        if (errors.length > 0) {
          this.errors.push(...errors);
          this.$emit('error');
        } else {
          this.$emit('added');
        }
      } catch (e) {
        Sentry.captureException(e);
        this.errors.push(CREATING_ERROR);
        this.$emit('error');
      } finally {
        this.loading = false;
      }
    },
    async updateDestination() {
      this.errors = [];
      this.loading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: googleCloudLoggingConfigurationUpdate,
          variables: {
            id: this.item.id,
            fullPath: this.groupPath,
            googleProjectIdName: this.googleProjectIdName,
            clientEmail: this.clientEmail,
            privateKey: this.privateKey,
            logIdName: this.logIdName,
          },
          context: {
            isSingleRequest: true,
          },
        });

        const {
          googleCloudLoggingConfigurationUpdate: { errors },
        } = data;

        if (errors.length > 0) {
          this.errors.push(...errors);
          this.$emit('error');
        } else {
          this.$emit('updated');
        }
      } catch (e) {
        Sentry.captureException(e);
        this.errors.push(UPDATING_ERROR);
        this.$emit('error');
      } finally {
        this.loading = false;
      }
    },
    deleteDestination() {
      this.$refs.deleteModal.show();
    },
    formSubmission() {
      return this.isEditing ? this.updateDestination() : this.addDestination();
    },
    privateKeyFormatter(value) {
      return value.replaceAll('\\n', '\n');
    },
  },
  i18n: ADD_STREAM_EDITOR_I18N,
  DESTINATION_TYPE_GCP_LOGGING,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="!isEditing"
      :title="$options.i18n.WARNING_TITLE"
      :dismissible="false"
      class="gl-mb-5"
      data-testid="data-warning"
      variant="warning"
    >
      {{ $options.i18n.WARNING_CONTENT }}
    </gl-alert>

    <gl-alert
      v-for="(error, index) in errors"
      :key="index"
      :dismissible="true"
      class="gl-mb-5"
      data-testid="alert-errors"
      variant="danger"
      @dismiss="clearError(index)"
    >
      {{ error }}
    </gl-alert>

    <gl-form @submit.prevent="formSubmission">
      <gl-form-group
        :label="$options.i18n.GCP_LOGGING_DESTINATION_PROJECT_ID_LABEL"
        data-testid="project-id-form-group"
      >
        <gl-form-input
          v-model="googleProjectIdName"
          :placeholder="$options.i18n.GCP_LOGGING_DESTINATION_PROJECT_ID_PLACEHOLDER"
          data-testid="project-id"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.GCP_LOGGING_DESTINATION_CLIENT_EMAIL_LABEL"
        data-testid="client-email-form-group"
      >
        <gl-form-input
          v-model="clientEmail"
          :placeholder="$options.i18n.GCP_LOGGING_DESTINATION_CLIENT_EMAIL_PLACEHOLDER"
          data-testid="client-email"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.GCP_LOGGING_DESTINATION_LOG_ID_LABEL"
        data-testid="log-id-form-group"
      >
        <gl-form-input
          v-model="logIdName"
          :placeholder="$options.i18n.GCP_LOGGING_DESTINATION_LOG_ID_PLACEHOLDER"
          data-testid="log-id"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.GCP_LOGGING_DESTINATION_PASSWORD_LABEL"
        data-testid="private-key-form-group"
      >
        <gl-form-textarea
          v-model="privateKey"
          rows="16"
          :formatter="privateKeyFormatter"
          class="gl-h-auto!"
          data-testid="private-key"
        />
      </gl-form-group>

      <div class="gl-display-flex">
        <gl-button
          :disabled="isSubmitButtonDisabled"
          :loading="loading"
          :name="addButtonName"
          class="gl-mr-3"
          variant="confirm"
          type="submit"
          data-testid="stream-destination-add-button"
          >{{ addButtonText }}</gl-button
        >
        <gl-button
          :name="$options.i18n.CANCEL_BUTTON_NAME"
          data-testid="stream-destination-cancel-button"
          @click="$emit('cancel')"
          >{{ $options.i18n.CANCEL_BUTTON_TEXT }}</gl-button
        >
        <gl-button
          v-if="isEditing"
          :name="$options.i18n.DELETE_BUTTON_TEXT"
          :loading="loading"
          variant="danger"
          class="gl-ml-auto"
          data-testid="stream-destination-delete-button"
          @click="deleteDestination"
          >{{ $options.i18n.DELETE_BUTTON_TEXT }}</gl-button
        >
      </div>
    </gl-form>
    <stream-delete-modal
      v-if="isEditing"
      ref="deleteModal"
      :type="$options.DESTINATION_TYPE_GCP_LOGGING"
      :item="item"
      @deleting="onDeleting"
      @delete="onDelete"
      @error="onError"
    />
  </div>
</template>
