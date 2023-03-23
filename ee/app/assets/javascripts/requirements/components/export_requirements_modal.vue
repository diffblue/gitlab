<script>
import { GlModal, GlSprintf, GlAlert, GlFormCheckbox } from '@gitlab/ui';
import { uniq } from 'lodash';
import { __, sprintf } from '~/locale';

export default {
  i18n: {
    modalTitle: __('Export %{requirementsCount} requirements?'),
  },
  modal: {
    actionPrimary: {
      text: __('Export requirements'),
      attributes: {
        variant: 'confirm',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  components: {
    GlModal,
    GlSprintf,
    GlFormCheckbox,
    GlAlert,
  },
  props: {
    email: {
      type: String,
      required: true,
    },
    requirementCount: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      selectedFields: this.$options.fields.map((f) => f.key),
    };
  },
  computed: {
    modalTitle() {
      return sprintf(this.$options.i18n.modalTitle, { requirementsCount: this.requirementCount });
    },
    selectedOptionsProps() {
      const selectedLength = this.selectedFields.length;
      const totalLength = this.$options.fields.length;

      let checked = false;

      if (selectedLength === 0) {
        checked = false;
      } else if (selectedLength === totalLength) {
        checked = true;
      }

      return {
        indeterminate: selectedLength !== 0 && selectedLength !== totalLength,
        checked,
      };
    },
  },
  methods: {
    show() {
      this.selectedFields = this.$options.fields.map((f) => f.key);
      this.$refs.modal.show();
    },
    hide() {
      this.$refs.modal.hide();
    },
    handleExport() {
      this.$emit('export', this.selectedFields);
    },
    toggleField(field) {
      const index = this.selectedFields.indexOf(field);
      if (index !== -1) {
        const tmp = [...this.selectedFields];
        tmp.splice(index, 1);
        this.selectedFields = tmp;
      } else {
        this.selectedFields = [...this.selectedFields, field];
      }
    },
    isFieldSelected(field) {
      return this.selectedFields.includes(field);
    },
    toggleAllFields() {
      const { indeterminate, checked } = this.selectedOptionsProps;

      if (indeterminate) {
        this.selectedFields = uniq([
          ...this.selectedFields,
          ...this.$options.fields.map((f) => f.key),
        ]);
        return;
      }

      if (checked) {
        this.selectedFields = [];
      } else {
        this.selectedFields = [...this.$options.fields.map((f) => f.key)];
      }
    },
  },
  /* eslint-disable @gitlab/require-i18n-strings */
  fields: [
    { key: 'requirement id', value: 'Requirement ID' },
    { key: 'title', value: 'Title' },
    { key: 'description', value: 'Description' },
    { key: 'author', value: 'Author' },
    { key: 'author username', value: 'Author Username' },
    { key: 'created at (utc)', value: 'Created At (UTC)' },
    { key: 'state', value: 'State' },
    { key: 'state updated at (utc)', value: 'State Updated At (UTC)' },
  ],
  /* eslint-enable @gitlab/require-i18n-strings */
};
</script>

<template>
  <gl-modal
    ref="modal"
    size="sm"
    modal-id="export-requirements"
    dialog-class="gl-mx-5"
    :title="modalTitle"
    :action-primary="$options.modal.actionPrimary"
    :action-secondary="$options.modal.actionSecondary"
    @primary="handleExport"
  >
    <p>
      <gl-alert :dismissible="false">
        <gl-sprintf :message="__('These will be sent to %{email} in an attachment once finished.')">
          <template #email>
            <strong>{{ email }}</strong>
          </template>
        </gl-sprintf>
      </gl-alert>
    </p>

    <div>
      <h5 class="gl-mb-0! gl-mt-5">{{ __('Advanced export options') }}</h5>
      <p class="gl-mb-3">
        {{ __('Please select what should be included in each exported requirement.') }}
      </p>

      <div class="scrollbox gl-mb-3">
        <div class="scrollbox-header gl-p-5">
          <gl-form-checkbox
            v-bind="selectedOptionsProps"
            class="gl-mb-0 gl-mr-0"
            @change="toggleAllFields"
            >{{ __('Select all') }}</gl-form-checkbox
          >
        </div>
        <div class="gl-pt-5 gl-pb-4 gl-pl-6 scrollbox-body">
          <gl-form-checkbox
            v-for="field in $options.fields"
            :key="field.key"
            class="gl-mb-0 gl-mr-0 form-check gl-pb-5 gl-ml-5"
            :checked="isFieldSelected(field.key)"
            @change="() => toggleField(field.key)"
            >{{ field.value }}</gl-form-checkbox
          >
        </div>
        <div class="scrollbox-fade"></div>
      </div>
    </div>
  </gl-modal>
</template>
