<script>
import { GlAlert, GlFormInput, GlFormGroup, GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, s__ } from '~/locale';
import NamespaceLimitsChangelog from './namespace_limits_changelog.vue';

const i18n = {
  updateLimitsButton: s__('NamespaceLimits|Update limit'),
  modalTitle: __('Are you sure?'),
  limitValidationError: s__('NamespaceLimits|Enter a valid number greater or equal to zero.'),
};

const modalActionsProps = {
  modalCancelProps: {
    text: __('Cancel'),
  },
  modalConfirmProps: {
    text: s__('NamespaceLimits|Confirm limits change'),
    attributes: {
      variant: 'danger',
    },
  },
};

export default {
  name: 'NamespaceLimitsSection',
  components: {
    GlAlert,
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlModal,
    NamespaceLimitsChangelog,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    limit: {
      type: Number,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    changelogEntries: {
      type: Array,
      required: false,
      default: () => [],
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
    modalBody: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      value: String(this.limit),
      validationError: '',
      modalId: uniqueId('namespace-limits-'),
    };
  },
  computed: {
    error() {
      return this.errorMessage || this.validationError;
    },
  },
  watch: {
    limit(limit) {
      this.value = String(limit);
    },
  },
  i18n,
  ...modalActionsProps,
  methods: {
    confirmChangingLimits() {
      // clear any previous validation errors
      this.validationError = '';

      // validate the limit is a positive number
      if (!this.value || Number(this.value) < 0) {
        this.validationError = i18n.limitValidationError;
        return;
      }

      this.$emit('limit-change', this.value);
    },
  },
};
</script>

<template>
  <div>
    <div>
      <gl-alert v-if="error" class="gl-mb-4" variant="danger" :dismissible="false">
        {{ error }}
      </gl-alert>
      <gl-form-group :label="label" :description="description" class="gl-lg-w-half">
        <gl-form-input v-model="value" size="md" type="number" min="0" />
      </gl-form-group>
      <gl-button v-gl-modal="modalId" variant="danger">{{
        $options.i18n.updateLimitsButton
      }}</gl-button>
      <gl-modal
        :modal-id="modalId"
        :title="$options.i18n.modalTitle"
        :action-primary="$options.modalConfirmProps"
        :action-cancel="$options.modalCancelProps"
        @primary="confirmChangingLimits"
      >
        {{ modalBody }}
      </gl-modal>
    </div>
    <namespace-limits-changelog :entries="changelogEntries" />
  </div>
</template>
