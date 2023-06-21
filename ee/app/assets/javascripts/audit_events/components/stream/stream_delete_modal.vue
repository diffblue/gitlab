<script>
import { GlModal, GlSprintf } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import externalDestinationsQuery from '../../graphql/queries/get_external_destinations.query.graphql';
import instanceExternalDestinationsQuery from '../../graphql/queries/get_instance_external_destinations.query.graphql';
import deleteExternalDestination from '../../graphql/mutations/delete_external_destination.mutation.graphql';
import deleteInstanceExternalDestination from '../../graphql/mutations/delete_instance_external_destination.mutation.graphql';

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
  },
  computed: {
    isInstance() {
      return this.groupPath === 'instance';
    },
    destinationQuery() {
      return this.isInstance ? instanceExternalDestinationsQuery : externalDestinationsQuery;
    },
    destinationDestroyMutation() {
      return this.isInstance ? deleteInstanceExternalDestination : deleteExternalDestination;
    },
  },
  methods: {
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

        const errors = this.isInstance
          ? data.instanceExternalAuditEventDestinationDestroy.errors
          : data.externalAuditEventDestinationDestroy.errors;

        if (errors.length > 0) {
          this.reportError(new Error(errors[0]));
        } else {
          this.reportSuccess(this.id);
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
    reportSuccess(id) {
      this.$emit('delete', id);
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
        <strong>{{ item.destinationUrl }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
