<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { sprintf } from '~/locale';
import deleteExternalDestination from '../../graphql/delete_external_destination.mutation.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS, STREAM_ITEMS_I18N } from '../../constants';
import StreamDestinationEditor from './stream_destination_editor.vue';

export default {
  components: {
    GlButton,
    StreamDestinationEditor,
  },
  directives: {
    GlTooltip,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      isDeleting: false,
    };
  },
  computed: {
    editButtonLabel() {
      return sprintf(STREAM_ITEMS_I18N.EDIT_BUTTON_LABEL, { link: this.item.destinationUrl });
    },
    deleteButtonLabel() {
      return sprintf(STREAM_ITEMS_I18N.DELETE_BUTTON_LABEL, { link: this.item.destinationUrl });
    },
  },
  methods: {
    setEditMode(state) {
      this.isEditing = state;
    },
    onUpdated(event) {
      this.setEditMode(false);
      this.$emit('updated', event);
    },
    async deleteDestination() {
      this.isDeleting = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteExternalDestination,
          variables: {
            id: this.item.id,
          },
          context: {
            isSingleRequest: true,
          },
        });

        const { errors } = data.externalAuditEventDestinationDestroy;
        if (errors.length > 0) {
          createAlert({
            message: errors[0],
          });
        } else {
          this.$emit('delete');
        }
      } catch (error) {
        createAlert({
          message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
          captureError: true,
          error,
        });
      } finally {
        this.isDeleting = false;
      }
    },
  },
  i18n: { ...AUDIT_STREAMS_NETWORK_ERRORS, ...STREAM_ITEMS_I18N },
};
</script>

<template>
  <li class="list-item py-0">
    <div
      class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-pl-5 gl-pr-3 gl-rounded-base"
      :class="[isEditing ? 'gl-py-5' : 'gl-py-3']"
    >
      <span class="gl-display-block" tabindex="0">{{ item.destinationUrl }}</span>
      <code
        v-gl-tooltip
        :title="$options.i18n.VERIFICATION_TOKEN_TOOLTIP"
        class="gl-ml-auto gl-mr-3"
        tabindex="0"
      >
        <span class="gl-sr-only">{{ $options.i18n.VERIFICATION_TOKEN_TOOLTIP }}:</span>
        {{ item.verificationToken }}
      </code>
      <div v-if="!isEditing">
        <gl-button
          v-gl-tooltip
          :aria-label="editButtonLabel"
          :disabled="isDeleting"
          :title="$options.i18n.EDIT_BUTTON_TOOLTIP"
          category="tertiary"
          icon="pencil"
          data-testid="edit-btn"
          @click="setEditMode(true)"
        />
        <gl-button
          v-gl-tooltip
          :aria-label="deleteButtonLabel"
          :loading="isDeleting"
          :title="$options.i18n.DELETE_BUTTON_TOOLTIP"
          category="tertiary"
          icon="remove"
          data-testid="delete-btn"
          @click="deleteDestination"
        />
      </div>
    </div>
    <div v-if="isEditing" class="gl-p-4">
      <stream-destination-editor :item="item" @added="onUpdated" @cancel="setEditMode(false)" />
    </div>
  </li>
</template>
