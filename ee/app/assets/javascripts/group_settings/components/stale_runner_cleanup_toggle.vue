<script>
import { GlToggle, GlSprintf } from '@gitlab/ui';
import { duration } from '~/lib/utils/datetime/timeago_utility';
import { s__, n__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { helpPagePath } from '~/helpers/help_page_helper';

import { I18N_UPDATE_ERROR_MESSAGE, I18N_REFRESH_MESSAGE } from '~/group_settings/constants';
import groupStaleRunnerPruningQuery from '../graphql/group_stale_runner_pruning.query.graphql';
import setGroupStaleRunnerPruningMutation from '../graphql/set_group_stale_runner_pruning.mutation.graphql';

export default {
  components: {
    GlToggle,
    GlSprintf,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    staleTimeoutSecs: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isSaving: false,
      staleRunnerCleanupEnabled: false,
      staleRunnersCount: null,
    };
  },
  apollo: {
    staleRunnerCleanupEnabled: {
      query: groupStaleRunnerPruningQuery,
      manual: true,
      variables() {
        return { fullPath: this.groupFullPath };
      },
      result({ data }) {
        const { group } = data;
        this.staleRunnersCount = group.runners.count;
        this.staleRunnerCleanupEnabled = group.allowStaleRunnerPruning;
      },
    },
  },
  computed: {
    staleTimeoutDuration() {
      return duration(this.staleTimeoutSecs * 1000);
    },
    isLoading() {
      return this.$apollo.queries.staleRunnerCleanupEnabled.loading;
    },
    staleRunnerCleanupHelpPagePath() {
      return helpPagePath('ci/runners/configure_runners', {
        anchor: 'view-stale-runner-cleanup-logs',
      });
    },
    confirmMsg() {
      return sprintf(
        s__(
          'Runners|All group runners that have not contacted GitLab in more than %{elapsedTime} are deleted permanently. This task runs periodically in the background.',
        ),
        { elapsedTime: this.staleTimeoutDuration },
      );
    },
    staleCountMsg() {
      if (!this.staleRunnersCount) {
        return s__('Runners|This group currently has no stale runners.');
      }
      return n__(
        'Runners|This group currently has 1 stale runner.',
        'Runners|This group currently has %d stale runners.',
        this.staleRunnersCount,
      );
    },
  },
  methods: {
    onChange: ignoreWhilePending(async function onChange(value) {
      if (this.isSaving || this.isLoading) {
        return;
      }
      if (value) {
        const confirmed = await confirmAction(null, {
          title: s__('Runners|Enable stale runner cleanup?'),
          modalHtmlMessage: `
            <p>${this.confirmMsg}</p>
            <p>${this.staleCountMsg}</p>
          `,
          primaryBtnText: s__('Runners|Yes, start deleting stale runners'),
          primaryBtnVariant: 'danger',
        });
        if (!confirmed) {
          return;
        }
      }

      try {
        this.isSaving = true;
        const {
          data: { namespaceCiCdSettingsUpdate },
        } = await this.$apollo.mutate({
          mutation: setGroupStaleRunnerPruningMutation,
          variables: {
            input: {
              fullPath: this.groupFullPath,
              allowStaleRunnerPruning: value,
            },
          },
        });

        const { errors } = namespaceCiCdSettingsUpdate;
        if (errors?.length) {
          throw new Error(errors[0], {
            cause: errors,
          });
        }
        this.staleRunnerCleanupEnabled =
          namespaceCiCdSettingsUpdate.ciCdSettings.allowStaleRunnerPruning;
      } catch (e) {
        this.onError(e);
      } finally {
        this.isSaving = false;
      }
    }),
    onError(error) {
      createAlert({
        message: `${I18N_UPDATE_ERROR_MESSAGE} ${I18N_REFRESH_MESSAGE}`,
        captureError: true,
        error,
      });
    },
  },
};
</script>

<template>
  <section class="gl-mb-5">
    <gl-toggle
      :value="staleRunnerCleanupEnabled"
      data-testid="stale-runner-cleanup-toggle"
      :is-loading="isLoading || isSaving"
      :label="s__('Runners|Enable stale runner cleanup')"
      @change="onChange"
    >
      <template #help>
        <gl-sprintf
          :message="
            s__(
              'Runners|A periodic background task deletes runners that haven\'t contacted GitLab in more than %{elapsedTime}. Only runners registered in this group are deleted. Runners in subgroups and projects are not. %{linkStart}Can I view how many runners were deleted?%{linkEnd}',
            )
          "
        >
          <template #elapsedTime>{{ staleTimeoutDuration }}</template>
          <template #link="{ content }">
            <a :href="staleRunnerCleanupHelpPagePath">{{ content }}</a>
          </template>
        </gl-sprintf>
      </template>
    </gl-toggle>
  </section>
</template>
