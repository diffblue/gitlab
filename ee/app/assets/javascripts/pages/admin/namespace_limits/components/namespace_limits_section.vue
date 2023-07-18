<script>
import {
  GlAlert,
  GlSprintf,
  GlLink,
  GlFormInput,
  GlFormGroup,
  GlButton,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, s__ } from '~/locale';

const i18n = {
  changelogTitle: __('Changelog'),
  changelogEntry: s__(
    'NamespaceLimits|%{linkStart}%{username}%{linkEnd} changed the limit to %{limit} at %{date}',
  ),
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
  components: { GlAlert, GlSprintf, GlLink, GlFormInput, GlFormGroup, GlButton, GlModal },
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
    <template v-if="changelogEntries.length">
      <p class="gl-mt-4 gl-mb-2 gl-font-weight-bold">{{ $options.i18n.changelogTitle }}</p>
      <ul data-testid="changelog-entries">
        <li v-for="(entry, index) in changelogEntries" :key="index">
          <gl-sprintf :message="$options.i18n.changelogEntry">
            <template #link>
              <gl-link :href="entry.user_web_url">{{ entry.username }}</gl-link>
            </template>
            <template #limit>
              {{ entry.limit }}
            </template>
            <template #date>
              {{ entry.date }}
            </template>
          </gl-sprintf>
        </li>
      </ul>
    </template>
  </div>
</template>
