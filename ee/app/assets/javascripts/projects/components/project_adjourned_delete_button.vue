<script>
import { GlAlert, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

export default {
  components: {
    GlAlert,
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
    alertTitle: __('You are about to permanently delete this project'),
    alertBody: __(
      "After a project is permanently deleted, it %{strongStart}cannot be recovered%{strongEnd}. You will lose this project's repository and %{strongStart}all related resources%{strongEnd}, including issues and merge requests.",
    ),
    helpLabel: __('Recovering projects'),
    recoveryMessage: __('You can recover this project until %{date}'),
    isNotForkMessage: __(
      'This project is %{strongStart}NOT%{strongEnd} a fork, and has the following:',
    ),
    isForkMessage: __('This forked project has the following:'),
  },
};
</script>

<template>
  <shared-delete-button v-bind="{ confirmPhrase, formPath }">
    <template #modal-body>
      <gl-alert
        class="gl-mb-5"
        variant="danger"
        :title="$options.strings.alertTitle"
        :dismissible="false"
      >
        <p>
          <gl-sprintf v-if="isFork" :message="$options.strings.isForkMessage" />
          <gl-sprintf v-else :message="$options.strings.isNotForkMessage">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <ul>
          <li>
            <gl-sprintf :message="n__('%d issue', '%d issues', issuesCount)">
              <template #issuesCount>{{ issuesCount }}</template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf
              :message="n__('%d merge requests', '%d merge requests', mergeRequestsCount)"
            >
              <template #mergeRequestsCount>{{ mergeRequestsCount }}</template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf :message="n__('%d fork', '%d forks', forksCount)">
              <template #forksCount>{{ forksCount }}</template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf :message="n__('%d star', '%d stars', starsCount)">
              <template #starsCount>{{ starsCount }}</template>
            </gl-sprintf>
          </li>
        </ul>
        <gl-sprintf :message="$options.strings.alertBody">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </gl-alert>
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
