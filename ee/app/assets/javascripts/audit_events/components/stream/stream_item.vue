<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlFormInputGroup,
  GlLink,
  GlModal,
  GlPopover,
  GlSprintf,
  GlCollapse,
  GlIcon,
  GlButton,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import deleteExternalDestination from '../../graphql/mutations/delete_external_destination.mutation.graphql';
import deleteInstanceExternalDestination from '../../graphql/mutations/delete_instance_external_destination.mutation.graphql';
import { AUDIT_STREAMS_NETWORK_ERRORS, STREAM_ITEMS_I18N } from '../../constants';
import StreamDestinationEditor from './stream_destination_editor.vue';

export default {
  components: {
    ClipboardButton,
    GlBadge,
    GlDisclosureDropdown,
    GlFormInputGroup,
    GlLink,
    GlModal,
    GlPopover,
    GlSprintf,
    GlCollapse,
    GlButton,
    GlIcon,
    StreamDestinationEditor,
  },
  directives: {
    GlTooltip,
  },
  inject: ['groupPath'],
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
    primaryModalAction() {
      return { text: __('Done') };
    },
    actions() {
      return [
        {
          text: __('Edit'),
          extraAttrs: { 'data-testid': 'edit-btn' },
          action: () => {
            this.toggleEditMode();
          },
        },
        {
          text: this.$options.i18n.VIEW_BUTTON_LABEL,
          extraAttrs: { 'data-testid': 'view-btn' },
          action: () => {
            this.$refs.tokenModal.show();
          },
        },
        {
          text: __('Delete'),
          extraAttrs: { 'data-testid': 'delete-btn', class: 'gl-text-red-500!' },
          action: () => this.deleteDestination(),
        },
      ];
    },
    verificationTokenClasses() {
      if (this.isEditing) {
        return '';
      }

      return 'gl-mr-3';
    },
    isItemFiltered() {
      return Boolean(this.item?.eventTypeFilters?.length);
    },
    isInstance() {
      return this.groupPath === 'instance';
    },
    destinationDestroyMutation() {
      return this.isInstance ? deleteInstanceExternalDestination : deleteExternalDestination;
    },
  },
  methods: {
    toggleEditMode() {
      this.isEditing = !this.isEditing;
    },
    onUpdated(event) {
      this.toggleEditMode();
      this.$emit('updated', event);
    },
    onEditorError() {
      this.$emit('error');
    },
    getQueryResponse(queryData) {
      return this.isInstance
        ? queryData.externalAuditEventDestinationCreate
        : queryData.group.externalAuditEventDestinationCreate;
    },
    async deleteDestination() {
      this.isDeleting = true;
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
    <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-py-5">
      <gl-button
        variant="link"
        class="gl-text-body! gl-font-weight-bold gl-min-w-0"
        :aria-expanded="isEditing"
        data-testid="toggle-btn"
        @click="toggleEditMode"
      >
        <gl-icon
          name="chevron-right"
          class="gl-transition-medium"
          :class="{ 'gl-rotate-90': isEditing }"
        /><span class="gl-font-lg gl-ml-2">{{ item.destinationUrl }}</span>
      </gl-button>

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
        <gl-badge
          :id="item.id"
          icon="filter"
          variant="neutral"
          data-testid="filter-badge"
          size="sm"
          class="gl-ml-3 gl-mr-auto"
        >
          {{ $options.i18n.FILTER_BADGE_LABEL }}
        </gl-badge>
      </template>
      <gl-disclosure-dropdown
        class="gl-ml-3"
        icon="ellipsis_v"
        :loading="isDeleting"
        :toggle-text="__('Actions')"
        no-caret
        text-sr-only
        :items="actions"
      />
      <gl-modal
        ref="tokenModal"
        :title="$options.i18n.VERIFICATION_TOKEN_TOOLTIP"
        modal-id="tokenModal"
        :action-primary="primaryModalAction"
      >
        <gl-sprintf :message="$options.i18n.VERIFICATION_TOKEN_MODAL_CONTENT">
          <template #link>{{ item.destinationUrl }}</template> </gl-sprintf
        >:

        <gl-form-input-group readonly :value="item.verificationToken" class="gl-mt-5">
          <template #append>
            <clipboard-button :text="item.verificationToken" :title="__('Copy to clipboard')" />
          </template>
        </gl-form-input-group>
      </gl-modal>
    </div>
    <gl-collapse :visible="isEditing">
      <stream-destination-editor
        v-if="isEditing"
        :item="item"
        class="gl-pr-0 gl-pl-6 gl-pb-5"
        @updated="onUpdated"
        @error="onEditorError"
        @cancel="toggleEditMode"
      />
    </gl-collapse>
  </li>
</template>
