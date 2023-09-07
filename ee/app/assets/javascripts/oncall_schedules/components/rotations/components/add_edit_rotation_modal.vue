<script>
import { GlModal, GlAlert } from '@gitlab/ui';
import { cloneDeep, set } from 'lodash';
import { LENGTH_ENUM } from 'ee/oncall_schedules/constants';
import createOncallScheduleRotationMutation from 'ee/oncall_schedules/graphql/mutations/create_oncall_schedule_rotation.mutation.graphql';
import updateOncallScheduleRotationMutation from 'ee/oncall_schedules/graphql/mutations/update_oncall_schedule_rotation.mutation.graphql';
import getOncallSchedulesWithRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import { updateStoreAfterRotationEdit } from 'ee/oncall_schedules/utils/cache_updates';
import {
  isNameFieldValid,
  parseHour,
  parseRotationDate,
  getParticipantsForSave,
} from 'ee/oncall_schedules/utils/common_utils';
import searchProjectMembersQuery from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import { format24HourTimeStringFromInt, formatDate } from '~/lib/utils/datetime_utility';
import { s__, __ } from '~/locale';
import AddEditRotationForm from './add_edit_rotation_form.vue';

export const i18n = {
  rotationCreated: s__('OnCallSchedules|Successfully created a new rotation'),
  editedRotation: s__('OnCallSchedules|Successfully edited your rotation'),
  addRotation: s__('OnCallSchedules|Add rotation'),
  editRotation: s__('OnCallSchedules|Edit rotation'),
  saveChanges: __('Save changes'),
  cancel: __('Cancel'),
};

export const formEmptyState = {
  name: '',
  participants: [],
  rotationLength: {
    length: 1,
    unit: LENGTH_ENUM.days,
  },
  startsAt: {
    date: null,
    time: 0,
  },
  isEndDateEnabled: false,
  endsAt: {
    date: null,
    time: 0,
  },
  isRestrictedToTime: false,
  restrictedTo: {
    startTime: 0,
    endTime: 0,
  },
};

const validiationInitialState = {
  name: true,
  participants: true,
  rotationLength: true,
  startsAt: true,
  endsAt: true,
};

export default {
  i18n,
  components: {
    GlModal,
    GlAlert,
    AddEditRotationForm,
  },
  inject: ['projectPath'],
  props: {
    modalId: {
      type: String,
      required: true,
    },
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    rotation: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    schedule: {
      type: Object,
      required: true,
    },
  },
  apollo: {
    participants: {
      query: searchProjectMembersQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          search: this.ptSearchTerm,
        };
      },
      update({ project: { projectMembers: { nodes = [] } = {} } = {} } = {}) {
        return nodes.filter((x) => x?.user).map(({ user }) => ({ ...user }));
      },
      error(error) {
        this.error = error;
      },
    },
  },
  data() {
    return {
      participants: [],
      loading: false,
      ptSearchTerm: '',
      form: cloneDeep(formEmptyState),
      error: '',
      validationState: cloneDeep(validiationInitialState),
    };
  },
  computed: {
    actionsProps() {
      return {
        primary: {
          text: this.primaryBtnText,
          attributes: { variant: 'confirm', loading: this.loading, disabled: !this.isFormValid },
        },
        cancel: {
          text: this.$options.i18n.cancel,
        },
      };
    },
    canFormSubmit() {
      return (
        isNameFieldValid(this.form.name) &&
        this.form.participants.length > 0 &&
        Boolean(this.form.startsAt.date)
      );
    },
    isFormValid() {
      return Object.values(this.validationState).every(Boolean) && this.canFormSubmit;
    },
    isLoading() {
      return this.loading || this.$apollo.queries.participants.loading;
    },
    rotationVariables() {
      const {
        name,
        rotationLength,
        participants,
        startsAt: { date: startDate, time: startTime },
        endsAt: { date: endDate, time: endTime },
        isEndDateEnabled,
        isRestrictedToTime,
        restrictedTo: { startTime: activeStartTime, endTime: activeEndTime },
      } = this.form;
      const variables = {
        name,
        participants: getParticipantsForSave(participants),
        rotationLength: {
          ...rotationLength,
          length: parseInt(rotationLength.length, 10),
        },
        startsAt: {
          date: formatDate(startDate, 'yyyy-mm-dd'),
          time: format24HourTimeStringFromInt(startTime),
        },
        endsAt: isEndDateEnabled
          ? {
              date: formatDate(endDate, 'yyyy-mm-dd'),
              time: format24HourTimeStringFromInt(endTime),
            }
          : null,
        activePeriod: isRestrictedToTime
          ? {
              startTime: format24HourTimeStringFromInt(activeStartTime),
              endTime: format24HourTimeStringFromInt(activeEndTime),
            }
          : null,
      };
      return variables;
    },
    title() {
      return this.isEditMode ? i18n.editRotation : i18n.addRotation;
    },
    primaryBtnText() {
      return this.isEditMode ? i18n.saveChanges : i18n.addRotation;
    },
    isEndDateValid() {
      const startsAt = new Date(this.form.startsAt.date).getTime();
      const endsAt = new Date(this.form.endsAt.date).getTime();

      if (!startsAt || !endsAt) {
        // If start or end is not present, we consider the end date valid
        return true;
      }
      if (startsAt < endsAt) {
        return true;
      }
      if (startsAt === endsAt) {
        return this.form.startsAt.time < this.form.endsAt.time;
      }
      return false;
    },
  },
  methods: {
    createRotation() {
      this.loading = true;
      const input = {
        ...this.rotationVariables,
        projectPath: this.projectPath,
        scheduleIid: this.schedule.iid,
      };
      this.$apollo
        .mutate({
          mutation: createOncallScheduleRotationMutation,
          variables: { input },
        })
        .then(
          ({
            data: {
              oncallRotationCreate: {
                errors: [error],
              },
            },
          }) => {
            if (error) {
              throw error;
            }
            this.loading = false;
            this.$refs.addEditScheduleRotationModal.hide();
            this.$emit('rotation-updated', i18n.rotationCreated);
          },
        )
        .catch((error) => {
          this.error = error;
          this.loading = false;
        });
    },
    editRotation() {
      this.loading = true;
      const { projectPath, schedule } = this;
      const input = {
        ...this.rotationVariables,
        id: this.rotation.id,
      };
      this.$apollo
        .mutate({
          mutation: updateOncallScheduleRotationMutation,
          variables: { input },
          update(store, { data }) {
            updateStoreAfterRotationEdit(
              store,
              getOncallSchedulesWithRotationsQuery,
              { ...data, scheduleIid: schedule.iid },
              {
                projectPath,
              },
            );
          },
        })
        .then(
          ({
            data: {
              oncallRotationUpdate: {
                errors: [error],
              },
            },
          }) => {
            if (error) {
              throw error;
            }
            this.loading = false;
            this.$refs.addEditScheduleRotationModal.hide();
            this.$emit('rotation-updated', i18n.editedRotation);
          },
        )
        .catch((error) => {
          this.error = error;
          this.loading = false;
        });
    },
    updateRotationForm({ type, value }) {
      set(this.form, type, value);
      this.validateForm(type);
    },
    filterParticipants(query) {
      this.ptSearchTerm = query;
    },
    validateForm(key) {
      if (key === 'name') {
        this.validationState.name = isNameFieldValid(this.form.name);
      } else if (key === 'participants') {
        this.validationState.participants = this.form.participants.length > 0;
      } else if (key === 'rotationLength.length') {
        this.validationState.rotationLength = this.form.rotationLength.length > 0;
      } else if (key === 'startsAt.date' || key === 'startsAt.time') {
        this.validationState.startsAt = Boolean(this.form.startsAt.date);
        this.validationState.endsAt = this.isEndDateValid;
      } else if (key === 'endsAt.date' || key === 'endsAt.time') {
        this.validationState.endsAt = this.isEndDateValid;
      }
    },
    beforeShowModal() {
      if (this.isEditMode) {
        return this.parseRotation();
      }

      return this.resetModal();
    },
    resetModal() {
      if (!this.isLoading) {
        this.form = cloneDeep(formEmptyState);
        this.validationState = cloneDeep(validiationInitialState);
        this.error = '';
      }
    },
    parseRotation() {
      const scheduleTimezone = this.schedule.timezone;

      this.form.name = this.rotation.name;

      const participants = this.rotation?.participants?.nodes.map(({ user }) => user) ?? [];
      this.form.participants = participants;

      this.form.rotationLength = {
        length: this.rotation.length,
        unit: this.rotation.lengthUnit,
      };

      if (this.rotation.startsAt) {
        this.form.startsAt = parseRotationDate(this.rotation.startsAt, scheduleTimezone);
      }

      if (this.rotation.endsAt) {
        this.form.isEndDateEnabled = true;
        this.form.endsAt = parseRotationDate(this.rotation.endsAt, scheduleTimezone);
      }

      if (this.rotation?.activePeriod?.startTime) {
        const { activePeriod } = this.rotation;
        this.form.isRestrictedToTime = true;
        this.form.restrictedTo.startTime = parseHour(activePeriod.startTime);
        this.form.restrictedTo.endTime = parseHour(activePeriod.endTime);
      }
    },
  },
};
</script>

<template>
  <gl-modal
    ref="addEditScheduleRotationModal"
    :modal-id="modalId"
    :title="title"
    :action-primary="actionsProps.primary"
    :action-cancel="actionsProps.cancel"
    modal-class="rotations-modal"
    @primary.prevent="isEditMode ? editRotation() : createRotation()"
    @show="beforeShowModal"
  >
    <gl-alert v-if="error" variant="danger" @dismiss="error = ''">
      {{ error || $options.i18n.errorMsg }}
    </gl-alert>
    <add-edit-rotation-form
      :validation-state="validationState"
      :form="form"
      :schedule="schedule"
      :participants="participants"
      :is-loading="isLoading"
      @update-rotation-form="updateRotationForm"
      @filter-participants="filterParticipants"
    />
  </gl-modal>
</template>
