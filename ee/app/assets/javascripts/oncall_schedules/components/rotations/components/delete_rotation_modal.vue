<script>
import { GlSprintf, GlModal, GlAlert } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import destroyOncallRotationMutation from 'ee/oncall_schedules/graphql/mutations/destroy_oncall_rotation.mutation.graphql';
import getOncallSchedulesQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import { updateStoreAfterRotationDelete } from 'ee/oncall_schedules/utils/cache_updates';
import { s__, __ } from '~/locale';

export const i18n = {
  deleteRotation: s__('OnCallSchedules|Delete rotation'),
  deleteRotationMessage: s__(
    'OnCallSchedules|Are you sure you want to delete the "%{deleteRotation}" rotation? This action cannot be undone.',
  ),
  cancel: __('Cancel'),
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
    rotation: {
      type: Object,
      required: true,
      validator: (rotation) =>
        isEmpty(rotation) || [rotation.id, rotation.name, rotation.startsAt].every(Boolean),
    },
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
      error: '',
    };
  },
  computed: {
    primaryProps() {
      return {
        text: this.$options.i18n.deleteRotation,
        attributes: { category: 'primary', variant: 'danger', loading: this.loading },
      };
    },
    cancelProps() {
      return {
        text: this.$options.i18n.cancel,
      };
    },
    rotationDeleteModalTestId() {
      return `delete-rotation-modal-${this.rotation.id}`;
    },
  },
  methods: {
    deleteRotation() {
      const {
        projectPath,
        rotation: { id },
        schedule: { iid },
      } = this;

      this.loading = true;
      this.$apollo
        .mutate({
          mutation: destroyOncallRotationMutation,
          variables: {
            id,
            scheduleIid: iid,
            projectPath,
          },
          update(store, { data }) {
            updateStoreAfterRotationDelete(
              store,
              getOncallSchedulesQuery,
              { ...data, scheduleIid: iid },
              {
                projectPath,
              },
            );
          },
        })
        .then(({ data: { oncallRotationDestroy } = {} } = {}) => {
          const error = oncallRotationDestroy.errors[0];
          if (error) {
            throw error;
          }
          this.$emit('rotation-deleted');
          this.$refs.deleteRotationModal.hide();
        })
        .catch((error) => {
          this.error = error;
        })
        .finally(() => {
          this.loading = false;
        });
    },
    hideErrorAlert() {
      this.error = '';
    },
  },
};
</script>

<template>
  <gl-modal
    ref="deleteRotationModal"
    :modal-id="modalId"
    size="sm"
    :data-testid="rotationDeleteModalTestId"
    :title="$options.i18n.deleteRotation"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary.prevent="deleteRotation"
    @cancel="$emit('set-rotation-to-update', {})"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mt-n3 gl-mb-3" @dismiss="hideErrorAlert">
      {{ error || $options.i18n.errorMsg }}
    </gl-alert>
    <gl-sprintf :message="$options.i18n.deleteRotationMessage">
      <template #deleteRotation>{{ rotation.name }}</template>
    </gl-sprintf>
  </gl-modal>
</template>
