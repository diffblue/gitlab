<script>
import {
  GlSprintf,
  GlLink,
  GlFormInput,
  GlFormGroup,
  GlButton,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';

const i18n = {
  changelogTitle: __('Changelog'),
  changelogEntry: s__(
    'NamespaceLimits|%{linkStart}%{username}%{linkEnd} changed the limit to %{limit} at %{date}',
  ),
  updateLimitsButton: s__('NamespaceLimits|Update limit'),
  modalTitle: __('Are you sure?'),
  modalBody: s__(
    'NamespaceLimits|This will limit the amount of notifications your namespace receives, this can be removed in the future.',
  ),
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

export const MODAL_ID = 'confirm-limits-change-modal';

export default {
  name: 'NamespaceLimitsSection',
  components: { GlSprintf, GlLink, GlFormInput, GlFormGroup, GlButton, GlModal },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    label: {
      type: String,
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
  },
  data() {
    return {
      limit: '',
    };
  },
  i18n,
  ...modalActionsProps,
  MODAL_ID,
  methods: {
    confirmChangingLimits() {
      this.$emit('limit-change', this.limit);
    },
  },
};
</script>

<template>
  <div>
    <div>
      <gl-form-group :label="label" :description="description" class="gl-lg-w-half">
        <gl-form-input v-model="limit" size="md" type="number" />
      </gl-form-group>
      <gl-button v-gl-modal="$options.MODAL_ID" variant="danger">{{
        $options.i18n.updateLimitsButton
      }}</gl-button>
      <gl-modal
        :modal-id="$options.MODAL_ID"
        :title="$options.i18n.modalTitle"
        :action-primary="$options.modalConfirmProps"
        :action-cancel="$options.modalCancelProps"
        @primary="confirmChangingLimits"
      >
        {{ $options.i18n.modalBody }}
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
