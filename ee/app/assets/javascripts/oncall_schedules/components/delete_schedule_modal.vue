<script>
import { GlSprintf, GlModal, GlAlert } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import destroyOncallScheduleMutation from '../graphql/mutations/destroy_oncall_schedule.mutation.graphql';
import getOncallSchedulesQuery from '../graphql/queries/get_oncall_schedules.query.graphql';
import { updateStoreAfterScheduleDelete } from '../utils/cache_updates';

export const i18n = {
  deleteSchedule: s__('OnCallSchedules|Delete schedule'),
  deleteScheduleMessage: s__(
    'OnCallSchedules|Are you sure you want to delete the "%{deleteSchedule}" schedule? This action cannot be undone.',
  ),
  escalationRulesWillBeDeletedMessage: s__(
    'OnCallScheduless|Any escalation rules that are using this schedule will also be deleted.',
  ),
};

export default {
  i18n,
  components: {
    GlSprintf,
    GlModal,
    GlAlert,
  },
  inject: ['projectPath'],
  props: {
    schedule: {
      type: Object,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      error: null,
    };
  },
  computed: {
    primaryProps() {
      return {
        text: this.$options.i18n.deleteSchedule,
        attributes: { category: 'primary', variant: 'danger', loading: this.loading },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    deleteSchedule() {
      const {
        projectPath,
        schedule: { iid },
      } = this;

      this.loading = true;
      this.$apollo
        .mutate({
          mutation: destroyOncallScheduleMutation,
          variables: {
            iid,
            projectPath,
          },
          update(store, { data }) {
            updateStoreAfterScheduleDelete(store, getOncallSchedulesQuery, data, { projectPath });
          },
        })
        .then(({ data: { oncallScheduleDestroy } = {} } = {}) => {
          const error = oncallScheduleDestroy.errors[0];
          if (error) {
            throw error;
          }
          this.$refs.deleteScheduleModal.hide();
        })
        .catch((error) => {
          this.error = error;
        })
        .finally(() => {
          this.loading = false;
        });
    },
    hideErrorAlert() {
      this.error = null;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="deleteScheduleModal"
    :modal-id="modalId"
    size="sm"
    :data-testid="`delete-schedule-modal-${schedule.iid}`"
    :title="$options.i18n.deleteSchedule"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary.prevent="deleteSchedule"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mt-n3 gl-mb-3" @dismiss="hideErrorAlert">
      {{ error || $options.i18n.errorMsg }}
    </gl-alert>
    <gl-sprintf :message="$options.i18n.deleteScheduleMessage">
      <template #deleteSchedule>{{ schedule.name }}</template>
    </gl-sprintf>
    <div class="gl-mt-5">
      {{ $options.i18n.escalationRulesWillBeDeletedMessage }}
    </div>
  </gl-modal>
</template>
