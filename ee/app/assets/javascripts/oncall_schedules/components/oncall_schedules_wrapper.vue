<script>
import {
  GlAlert,
  GlButton,
  GlEmptyState,
  GlLoadingIcon,
  GlLink,
  GlModalDirective,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import getOncallSchedulesWithRotationsQuery from '../graphql/queries/get_oncall_schedules.query.graphql';
import AddScheduleModal from './add_edit_schedule_modal.vue';
import OncallSchedule from './oncall_schedule.vue';

export const addScheduleModalId = 'addScheduleModal';

export const i18n = {
  title: s__('OnCallSchedules|On-call schedules'),
  add: {
    button: s__('OnCallSchedules|Add schedule'),
    tooltip: s__('OnCallSchedules|Add an additional schedule to your project'),
  },
  emptyState: {
    title: s__('OnCallSchedules|Create on-call schedules in GitLab'),
    description: s__('OnCallSchedules|Route alerts directly to specific members of your team'),
    unauthorizedDescription: s__(
      'OnCallSchedules|Route alerts directly to specific members of your team. To access this feature, ask %{linkStart}a project Owner%{linkEnd} to grant you at least the Maintainer role.',
    ),
  },
  successNotification: {
    title: s__('OnCallSchedules|Try adding a rotation'),
    description: s__(
      'OnCallSchedules|Your schedule has been successfully created. To add individual users to this schedule, use the Add a rotation button. To enable notifications for this schedule, you must also create an %{linkStart}escalation policy%{linkEnd}.',
    ),
  },
};

export default {
  i18n,
  addScheduleModalId,
  components: {
    GlAlert,
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
    GlLink,
    GlSprintf,
    AddScheduleModal,
    OncallSchedule,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'emptyOncallSchedulesSvgPath',
    'projectPath',
    'escalationPoliciesPath',
    'userCanCreateSchedule',
    'accessLevelDescriptionPath',
  ],
  data() {
    return {
      schedules: [],
      showScheduleCreatedNotification: false,
      showRotationUpdatedNotification: false,
      rotationUpdateMsg: null,
    };
  },
  apollo: {
    schedules: {
      query: getOncallSchedulesWithRotationsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data.project?.incidentManagementOncallSchedules?.nodes ?? [];
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.schedules.loading;
    },
    hasSchedules() {
      return this.schedules.length;
    },
  },
  methods: {
    onRotationUpdate(message) {
      this.showScheduleCreatedNotification = false;
      this.showRotationUpdatedNotification = true;
      this.rotationUpdateMsg = message;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3" />

    <template v-else-if="hasSchedules">
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <h1>{{ $options.i18n.title }}</h1>
        <gl-button
          v-if="userCanCreateSchedule"
          v-gl-modal="$options.addScheduleModalId"
          v-gl-tooltip.left.viewport.hover
          :title="$options.i18n.add.tooltip"
          :aria-label="$options.i18n.add.tooltip"
          category="primary"
          size="small"
          variant="confirm"
          class="gl-mt-5"
          data-testid="add-additional-schedules-button"
        >
          {{ $options.i18n.add.button }}
        </gl-button>
      </div>

      <gl-alert
        v-if="showScheduleCreatedNotification"
        data-testid="tip-alert"
        variant="tip"
        :title="$options.i18n.successNotification.title"
        class="gl-my-3"
        @dismiss="showScheduleCreatedNotification = false"
      >
        <gl-sprintf :message="$options.i18n.successNotification.description">
          <template #link="{ content }">
            <gl-link :href="escalationPoliciesPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>

      <gl-alert
        v-if="showRotationUpdatedNotification"
        data-testid="success-alert"
        variant="success"
        class="gl-my-3"
        @dismiss="showRotationUpdatedNotification = false"
      >
        {{ rotationUpdateMsg }}
      </gl-alert>

      <oncall-schedule
        v-for="(schedule, scheduleIndex) in schedules"
        :key="schedule.iid"
        :schedule="schedule"
        :schedule-index="scheduleIndex"
        @rotation-updated="onRotationUpdate"
      />
    </template>

    <gl-empty-state
      v-else
      :title="$options.i18n.emptyState.title"
      :svg-path="emptyOncallSchedulesSvgPath"
    >
      <template #description>
        <p v-if="userCanCreateSchedule">
          {{ $options.i18n.emptyState.description }}
        </p>
        <gl-sprintf v-else :message="$options.i18n.emptyState.unauthorizedDescription">
          <template #link="{ content }">
            <gl-link :href="accessLevelDescriptionPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
      <template v-if="userCanCreateSchedule" #actions>
        <gl-button
          v-gl-modal="$options.addScheduleModalId"
          variant="confirm"
          data-qa-selector="add_on_call_schedule_button"
        >
          {{ $options.i18n.add.button }}
        </gl-button>
      </template>
    </gl-empty-state>
    <add-schedule-modal
      :modal-id="$options.addScheduleModalId"
      @scheduleCreated="showScheduleCreatedNotification = true"
    />
  </div>
</template>
