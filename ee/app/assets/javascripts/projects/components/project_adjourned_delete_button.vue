<script>
import { GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

export default {
  components: {
    GlSprintf,
    GlIcon,
    GlLink,
    SharedDeleteButton,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
    adjournedRemovalDate: {
      type: String,
      required: true,
    },
    recoveryHelpPath: {
      type: String,
      required: true,
    },
  },
  strings: {
    modalBody: __(
      "Once a project is permanently deleted, it cannot be recovered. You will lose this project's repository and all related resources, including issues and merge requests.",
    ),
    helpLabel: __('Recovering projects'),
    recoveryMessage: __('You can recover this project until %{date}'),
  },
};
</script>

<template>
  <shared-delete-button v-bind="{ confirmPhrase, formPath }">
    <template #modal-body>
      <p>{{ $options.strings.modalBody }}</p>
    </template>
    <template #modal-footer>
      <p
        class="gl-display-flex gl-display-flex gl-align-items-center gl-mt-3 gl-mb-0 gl-text-gray-500"
      >
        <gl-sprintf :message="$options.strings.recoveryMessage">
          <template #date>
            {{ adjournedRemovalDate }}
          </template>
        </gl-sprintf>
        <gl-link
          :aria-label="$options.strings.helpLabel"
          class="gl-display-flex gl-ml-2 gl-text-gray-500"
          :href="recoveryHelpPath"
        >
          <gl-icon name="question" />
        </gl-link>
      </p>
    </template>
  </shared-delete-button>
</template>
