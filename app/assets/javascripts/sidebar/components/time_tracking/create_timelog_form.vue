<script>
import {
  GlFormGroup,
  GlFormInput,
  GlDatepicker,
  GlFormTextarea,
  GlModal,
  GlAlert,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/graphql_shared/constants';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import createTimelogMutation from '../../queries/create_timelog.mutation.graphql';

export const CREATE_TIMELOG_MODAL_ID = 'create-timelog-modal';

export default {
  components: {
    GlDatepicker,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlModal,
    GlAlert,
    GlLink,
    GlSprintf,
  },
  inject: ['issuableType'],
  props: {
    issuableId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      timeSpent: '',
      spentAt: null,
      summary: '',
      isLoading: false,
      saveError: '',
    };
  },
  computed: {
    submitDisabled() {
      return this.isLoading || this.timeSpent.length === 0;
    },
    primaryProps() {
      return {
        text: s__('CreateTimelogForm|Save'),
        attributes: [
          {
            variant: 'confirm',
            disabled: this.submitDisabled,
            loading: this.isLoading,
          },
        ],
      };
    },
    cancelProps() {
      return {
        text: s__('CreateTimelogForm|Cancel'),
      };
    },
    timeTrackignDocsPath() {
      return joinPaths(gon.relative_url_root || '', '/help/user/project/time_tracking.md');
    },
  },
  methods: {
    resetModal() {
      this.isLoading = false;
      this.timeSpent = '';
      this.spentAt = null;
      this.summary = '';
      this.saveError = '';
    },
    close() {
      this.resetModal();
      this.$refs.modal.close();
    },
    registerTimeSpent(event) {
      event.preventDefault();

      if (this.timeSpent.length === 0) {
        return;
      }

      this.isLoading = true;
      this.saveError = '';

      this.$apollo
        .mutate({
          mutation: createTimelogMutation,
          variables: {
            input: {
              timeSpent: this.timeSpent,
              spentAt: this.spentAt
                ? formatDate(this.spentAt, 'isoDateTime')
                : formatDate(Date.now(), 'isoDateTime'),
              summary: this.summary,
              issuableId: this.getIssuableId(),
            },
          },
        })
        .then(({ data }) => {
          if (data.timelogCreate?.errors.length) {
            this.saveError = data.timelogCreate?.errors[0].message || data.timelogCreate?.errors[0];
          } else {
            this.close();
          }
        })
        .catch((error) => {
          this.saveError =
            error?.message ||
            s__('CreateTimelogForm|An error occurred while saving the time entry.');
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    isIssue() {
      return this.issuableType === 'issue';
    },
    getGraphQLEntityType() {
      return this.isIssue() ? TYPE_ISSUE : TYPE_MERGE_REQUEST;
    },
    updateSpentAtDate(val) {
      this.spentAt = val;
    },
    getIssuableId() {
      return convertToGraphQLId(this.getGraphQLEntityType(), this.issuableId);
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :title="s__('CreateTimelogForm|Add time entry')"
    :modal-id="CREATE_TIMELOG_MODAL_ID"
    size="sm"
    data-testid="create-timelog-modal"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="registerTimeSpent"
    @cancel="close"
    @close="close"
  >
    <form
      class="gl-display-flex gl-flex-direction-column js-quick-submit"
      @submit.prevent="registerTimeSpent"
    >
      <div class="gl-display-flex gl-gap-3">
        <gl-form-group
          key="time-spent"
          label-for="time-spent"
          label="Time spent"
          :description="s__(`CreateTimelogForm|Example: 1h 30m`)"
        >
          <gl-form-input
            id="time-spent"
            v-model="timeSpent"
            class="gl-form-input-sm"
            autocomplete="off"
          />
        </gl-form-group>
        <gl-form-group key="spent-at" optional label-for="spent-at" label="Spent at">
          <gl-datepicker
            :target="null"
            :value="spentAt"
            show-clear-button
            autocomplete="off"
            size="small"
            @input="updateSpentAtDate"
            @clear="updateSpentAtDate(null)"
          />
        </gl-form-group>
      </div>
      <gl-form-group :label="s__('CreateTimelogForm|Summary')" optional label-for="summary">
        <gl-form-textarea id="summary" v-model="summary" rows="3" :no-resize="true" />
      </gl-form-group>
      <p class="gl-mb-0" data-testid="timetracking-docs-link">
        <gl-sprintf
          :message="
            s__(
              'CreateTimelogForm|View the full documentation on how time tracking works (e.g. setting estimated time) on %{timeTrackingDocsLinkStart}this page%{timeTrackingDocsLinkEnd}.',
            )
          "
        >
          <template #timeTrackingDocsLink>
            <gl-link :href="timeTrackignDocsPath" target="_blank">{{
              s__('CreateTimelogForm|this page')
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <gl-alert v-if="saveError" variant="danger" class="gl-mt-5" :dismissible="false">
        {{ saveError }}
      </gl-alert>
      <!-- This is needed to have the quick-submit behaviour (with Ctrl + Enter or Cmd + Enter) -->
      <input type="submit" hidden />
    </form>
  </gl-modal>
</template>
