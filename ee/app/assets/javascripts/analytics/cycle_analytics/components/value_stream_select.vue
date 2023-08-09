<script>
import {
  GlAlert,
  GlButton,
  GlCollapsibleListbox,
  GlModal,
  GlModalDirective,
  GlSprintf,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { slugifyWithUnderscore } from '~/lib/utils/text_utility';
import { sprintf, __, s__ } from '~/locale';
import Tracking from '~/tracking';
import ValueStreamForm from './value_stream_form.vue';

const i18n = {
  DELETE_NAME: s__('DeleteValueStream|Delete %{name}'),
  DELETE_CONFIRMATION: s__(
    'DeleteValueStream|Are you sure you want to delete the "%{name}" Value Stream?',
  ),
  DELETED: s__("DeleteValueStream|'%{name}' Value Stream deleted"),
  DELETE: __('Delete'),
  CREATE_VALUE_STREAM: s__('CreateValueStreamForm|Create new Value Stream'),
  CANCEL: __('Cancel'),
  EDIT_VALUE_STREAM: __('Edit'),
};

export default {
  components: {
    GlAlert,
    GlButton,
    GlCollapsibleListbox,
    GlModal,
    GlSprintf,
    ValueStreamForm,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  data() {
    return {
      showForm: false,
      isEditing: false,
    };
  },
  computed: {
    ...mapState({
      isDeleting: 'isDeletingValueStream',
      deleteValueStreamError: 'deleteValueStreamError',
      data: 'valueStreams',
      selectedValueStream: 'selectedValueStream',
    }),
    listBoxData() {
      return (
        this.data?.map(({ id: value, name: streamName }) => ({ value, text: streamName })) || []
      );
    },
    hasValueStreams() {
      return Boolean(this.data.length);
    },
    selectedValueStreamName() {
      return this.selectedValueStream?.name || '';
    },
    selectedValueStreamId() {
      return this.selectedValueStream?.id || null;
    },
    isCustomValueStream() {
      return this.selectedValueStream?.isCustom || false;
    },
    deleteConfirmationText() {
      return sprintf(this.$options.i18n.DELETE_CONFIRMATION, {
        name: this.selectedValueStreamName,
      });
    },
  },
  methods: {
    ...mapActions(['setSelectedValueStream', 'deleteValueStream']),
    onSuccess(message) {
      this.$toast.show(message);
    },
    isSelected(id) {
      return Boolean(this.selectedValueStreamId && this.selectedValueStreamId === id);
    },
    onSelect(selectedId) {
      const selectedItem = this.data.find(({ id }) => id === selectedId);
      this.track('click_dropdown', { label: this.slugify(selectedItem?.name) });
      this.setSelectedValueStream(selectedItem);
    },
    onDelete() {
      const name = this.selectedValueStreamName;
      return this.deleteValueStream(this.selectedValueStreamId).then(() => {
        if (!this.deleteValueStreamError) {
          this.onSuccess(sprintf(this.$options.i18n.DELETED, { name }));
          this.track('delete_value_stream', { extra: { name } });
        }
      });
    },
    onCreate() {
      this.showForm = true;
      this.isEditing = false;
    },
    onEdit() {
      this.showForm = true;
      this.isEditing = true;
    },
    slugify(valueStreamTitle) {
      return slugifyWithUnderscore(valueStreamTitle);
    },
  },
  i18n,
};
</script>
<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <label class="gl-m-0">{{ s__('ValueStreamAnalytics|Value stream') }}</label>
    <gl-collapsible-listbox
      v-if="hasValueStreams"
      data-testid="dropdown-value-streams"
      :items="listBoxData"
      :toggle-text="selectedValueStreamName"
      :selected="selectedValueStreamId"
      @select="onSelect"
    >
      <template #footer>
        <div class="gl-border-t gl-p-2">
          <gl-button
            v-gl-modal-directive="'value-stream-form-modal'"
            class="gl-w-full gl-justify-content-start!"
            category="tertiary"
            data-testid="create-value-stream"
            data-track-action="click_dropdown"
            data-track-label="create_value_stream_form_open"
            @click="onCreate"
            >{{ $options.i18n.CREATE_VALUE_STREAM }}</gl-button
          >
          <gl-button
            v-if="isCustomValueStream"
            v-gl-modal-directive="'delete-value-stream-modal'"
            class="gl-w-full gl-justify-content-start!"
            category="tertiary"
            variant="danger"
            data-testid="delete-value-stream"
            data-track-action="click_dropdown"
            data-track-label="delete_value_stream_form_open"
          >
            <gl-sprintf :message="$options.i18n.DELETE_NAME">
              <template #name>{{ selectedValueStreamName }}</template>
            </gl-sprintf>
          </gl-button>
        </div>
      </template>
    </gl-collapsible-listbox>
    <gl-button
      v-if="isCustomValueStream"
      v-gl-modal-directive="'value-stream-form-modal'"
      data-testid="edit-value-stream"
      data-track-action="click_button"
      data-track-label="edit_value_stream_form_open"
      @click="onEdit"
      >{{ $options.i18n.EDIT_VALUE_STREAM }}</gl-button
    >
    <gl-button
      v-if="!hasValueStreams"
      v-gl-modal-directive="'value-stream-form-modal'"
      data-testid="create-value-stream-button"
      data-track-action="click_button"
      data-track-label="create_value_stream_form_open"
      @click="onCreate"
      >{{ $options.i18n.CREATE_VALUE_STREAM }}</gl-button
    >
    <value-stream-form v-if="showForm" :is-editing="isEditing" @hidden="showForm = false" />
    <gl-modal
      data-testid="delete-value-stream-modal"
      modal-id="delete-value-stream-modal"
      :title="__('Delete Value Stream')"
      :action-primary="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: $options.i18n.DELETE,
        attributes: { variant: 'danger', loading: isDeleting },
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :action-cancel="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: $options.i18n.CANCEL,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      @primary.prevent="onDelete"
    >
      <gl-alert v-if="deleteValueStreamError" variant="danger">{{
        deleteValueStreamError
      }}</gl-alert>
      <p>
        <gl-sprintf :message="$options.i18n.DELETE_CONFIRMATION">
          <template #name>{{ selectedValueStreamName }}</template>
        </gl-sprintf>
      </p>
    </gl-modal>
  </div>
</template>
