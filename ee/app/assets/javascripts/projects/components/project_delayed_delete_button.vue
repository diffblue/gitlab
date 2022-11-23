<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

export default {
  components: {
    GlSprintf,
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
    delayedDeletionDate: {
      type: String,
      required: true,
    },
    restoreHelpPath: {
      type: String,
      required: true,
    },
    isFork: {
      type: Boolean,
      required: true,
    },
    issuesCount: {
      type: Number,
      required: true,
    },
    mergeRequestsCount: {
      type: Number,
      required: true,
    },
    forksCount: {
      type: Number,
      required: true,
    },
    starsCount: {
      type: Number,
      required: true,
    },
  },

  strings: {
    restoreLabel: __('Restoring projects'),
    restoreMessage: __('This project can be restored until %{date}.'),
  },
};
</script>

<template>
  <shared-delete-button
    :confirm-phrase="confirmPhrase"
    :form-path="formPath"
    :is-fork="isFork"
    :issues-count="issuesCount"
    :merge-requests-count="mergeRequestsCount"
    :forks-count="forksCount"
    :stars-count="starsCount"
  >
    <template #modal-footer>
      <p
        class="gl-display-flex gl-display-flex gl-align-items-center gl-mt-3 gl-mb-0 gl-text-gray-500"
      >
        <gl-sprintf :message="$options.strings.restoreMessage">
          <template #date>{{ delayedDeletionDate }}</template>
        </gl-sprintf>
        <gl-link
          :aria-label="$options.strings.restoreLabel"
          class="gl-display-flex gl-ml-2"
          :href="restoreHelpPath"
          >{{ __('Learn More.') }}
        </gl-link>
      </p>
    </template>
  </shared-delete-button>
</template>
