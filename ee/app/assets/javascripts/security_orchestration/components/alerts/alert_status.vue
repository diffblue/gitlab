<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import updateAlertStatusMutation from '~/graphql_shared/mutations/alert_status_update.mutation.graphql';
import { MESSAGES, STATUSES } from './constants';

export default {
  i18n: {
    STATUSES,
  },
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    alert: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isUpdating: false,
    };
  },
  methods: {
    handleError() {
      this.$emit('alert-error', MESSAGES.UPDATE_STATUS_ERROR);
    },
    async updateAlertStatus(status) {
      this.isUpdating = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateAlertStatusMutation,
          variables: {
            iid: this.alert.iid,
            status: status.toUpperCase(),
            projectPath: this.projectPath,
          },
        });

        const errors = data?.updateAlertStatus?.errors || [];
        if (errors[0]) {
          this.handleError();
        }

        this.$emit('alert-update');
      } catch {
        this.handleError();
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<template>
  <div class="dropdown dropdown-menu-selectable">
    <gl-dropdown
      :loading="isUpdating"
      right
      :text="$options.i18n.STATUSES[alert.status]"
      class="gl-w-full"
      toggle-class="dropdown-menu-toggle"
    >
      <div class="dropdown-content dropdown-body">
        <gl-dropdown-item
          v-for="(label, field) in $options.i18n.STATUSES"
          :key="field"
          :active="field === alert.status"
          active-class="is-active"
          @click="updateAlertStatus(field)"
        >
          {{ label }}
        </gl-dropdown-item>
      </div>
    </gl-dropdown>
  </div>
</template>
