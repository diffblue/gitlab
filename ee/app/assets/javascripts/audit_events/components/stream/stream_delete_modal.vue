<script>
import { GlModal, GlSprintf } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import deleteExternalDestination from '../../graphql/mutations/delete_external_destination.mutation.graphql';
import deleteInstanceExternalDestination from '../../graphql/mutations/delete_instance_external_destination.mutation.graphql';
import googleCloudLoggingConfigurationDestroy from '../../graphql/mutations/delete_gcp_logging_destination.mutation.graphql';
import { DESTINATION_TYPE_HTTP, DESTINATION_TYPE_GCP_LOGGING } from '../../constants';

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  inject: ['groupPath'],
  props: {
    item: {
      type: Object,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    isInstance() {
      return this.groupPath === 'instance';
    },
    destinationDestroyMutation() {
      switch (this.type) {
        case DESTINATION_TYPE_GCP_LOGGING:
          return googleCloudLoggingConfigurationDestroy;
        case DESTINATION_TYPE_HTTP:
        default:
          return this.isInstance ? deleteInstanceExternalDestination : deleteExternalDestination;
      }
    },
    destinationTitle() {
      switch (this.type) {
        case DESTINATION_TYPE_GCP_LOGGING:
          return this.item.googleProjectIdName;
        case DESTINATION_TYPE_HTTP:
        default:
          return this.item.destinationUrl;
      }
    },
  },
  methods: {
    destinationErrors(data) {
      switch (this.type) {
        case DESTINATION_TYPE_GCP_LOGGING:
          return data.googleCloudLoggingConfigurationDestroy.errors;
        case DESTINATION_TYPE_HTTP:
        default:
          return this.isInstance
            ? data.instanceExternalAuditEventDestinationDestroy.errors
            : data.externalAuditEventDestinationDestroy.errors;
      }
    },
    async deleteDestination() {
      this.reportDeleting();

      try {
        const { data } = await this.$apollo.mutate({
          mutation: this.destinationDestroyMutation,
          variables: {
            id: this.item.id,
            isInstance: this.isInstance,
          },
          context: {
            isSingleRequest: true,
          },
        });

        const errors = this.destinationErrors(data);

        if (errors.length > 0) {
          this.reportError(new Error(errors[0]));
        } else {
          this.$emit('delete');
        }
      } catch (error) {
        this.reportError(error);
      }
    },
    reportDeleting() {
      this.$emit('deleting');
    },
    reportError(error) {
      this.$emit('error', error);
    },
    show() {
      this.$refs.modal.show();
    },
  },
  i18n: {
    title: s__('AuditStreams|Are you sure about deleting this destination?'),
    message: s__(
      'AuditStreams|Deleting the streaming destination %{destination} will stop audit events being streamed',
    ),
  },
  buttonProps: {
    primary: {
      text: s__('AuditStreams|Delete destination'),
      attributes: { category: 'primary', variant: 'danger' },
    },
    cancel: {
      text: __('Cancel'),
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :title="$options.i18n.title"
    modal-id="delete-destination-modal"
    :action-primary="$options.buttonProps.primary"
    :action-cancel="$options.buttonProps.cancel"
    @primary="deleteDestination"
  >
    <gl-sprintf :message="$options.i18n.message">
      <template #destination>
        <strong>{{ destinationTitle }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
