<script>
import {
  GlButton,
  GlBadge,
  GlLink,
  GlPopover,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { sprintf } from '~/locale';
import { createAlert } from '~/flash';
import deleteExternalDestination from '../../graphql/delete_external_destination.mutation.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS, STREAM_ITEMS_I18N } from '../../constants';
import StreamDestinationEditor from './stream_destination_editor.vue';

export default {
  components: {
    GlButton,
    GlBadge,
    GlLink,
    GlPopover,
    GlSprintf,
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
    groupEventFilters: {
      type: Array,
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
    itemClasses() {
      return this.isEditing ? 'gl-py-5' : 'gl-py-3';
    },
    verificationTokenClasses() {
      if (this.isEditing) {
        return '';
      }

      return 'gl-mr-3';
    },
    editButtonLabel() {
      return sprintf(STREAM_ITEMS_I18N.EDIT_BUTTON_LABEL, { link: this.item.destinationUrl });
    },
    deleteButtonLabel() {
      return sprintf(STREAM_ITEMS_I18N.DELETE_BUTTON_LABEL, { link: this.item.destinationUrl });
    },
    isItemFiltered() {
      return Boolean(this.item?.eventTypeFilters?.length);
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
    onEditorError() {
      this.$emit('error');
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
          this.$emit('error');
        } else {
          this.$emit('deleted');
        }
      } catch (error) {
        createAlert({
          message: AUDIT_STREAMS_NETWORK_ERRORS.DELETING_ERROR,
          captureError: true,
          error,
        });
        this.$emit('error');
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
      class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-px-4 gl-rounded-base"
      :class="itemClasses"
    >
      <span class="gl-display-block" tabindex="0">{{ item.destinationUrl }}</span>
      <code
        v-gl-tooltip
        :title="$options.i18n.VERIFICATION_TOKEN_TOOLTIP"
        class="gl-ml-auto"
        :class="verificationTokenClasses"
        tabindex="0"
      >
        <span class="gl-sr-only">{{ $options.i18n.VERIFICATION_TOKEN_TOOLTIP }}:</span>
        {{ item.verificationToken }}
      </code>
      <template v-if="isItemFiltered">
        <gl-popover :target="item.id" data-testid="filter-popover">
          <gl-sprintf :message="$options.i18n.FILTER_TOOLTIP_LABEL">
            <template #link="{ content }">
              <gl-link :href="$options.i18n.FILTER_TOOLTIP_LINK" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </gl-popover>
        <gl-badge :id="item.id" icon="filter" variant="info" data-testid="filter-badge">
          {{ $options.i18n.FILTER_BADGE_LABEL }}
        </gl-badge>
      </template>
      <template v-if="!isEditing">
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
      </template>
    </div>
    <div v-if="isEditing" class="gl-p-4">
      <stream-destination-editor
        :item="item"
        :group-event-filters="groupEventFilters"
        @updated="onUpdated"
        @error="onEditorError"
        @cancel="setEditMode(false)"
      />
    </div>
  </li>
</template>
