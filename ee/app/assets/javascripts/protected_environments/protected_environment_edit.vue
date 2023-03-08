<script>
import { GlButton, GlLink, GlFormSelect } from '@gitlab/ui';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __, s__, sprintf } from '~/locale';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

export const i18n = {
  successMessage: __('Successfully updated the environment.'),
  failureMessage: __('Failed to update environment!'),
  label: __('Select'),
};

export default {
  i18n,
  ACCESS_LEVELS,
  accessLevelsData: gon?.deploy_access_levels?.roles ?? [],
  components: {
    AccessDropdown,
    GlButton,
    GlLink,
    GlFormSelect,
  },
  props: {
    parentContainer: {
      required: true,
      type: HTMLElement,
    },
    url: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    preselectedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    requiredApprovalCount: {
      type: Number,
      required: false,
      default: 0,
    },
    environmentName: {
      type: String,
      required: true,
    },
    environmentLink: {
      type: String,
      required: false,
      default: '',
    },
    deleteProtectedEnvironmentLink: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      preselected: this.preselectedItems,
      selected: null,
      count: this.requiredApprovalCount,
    };
  },
  computed: {
    hasChanges() {
      return this.selected.some(({ id, _destroy }) => id === undefined || _destroy);
    },
    confirmUnprotectText() {
      return sprintf(
        s__(
          'ProtectedEnvironment|%{environment_name} will be writable for developers. Are you sure?',
        ),
        { environment_name: this.environmentName },
      );
    },
  },
  methods: {
    updatePermissions(permissions) {
      this.selected = permissions;

      if (!this.hasChanges) {
        return;
      }

      this.patchEnvironment({
        protected_environment: { [`${ACCESS_LEVELS.DEPLOY}_attributes`]: permissions },
      })
        .then(({ data } = {}) => {
          if (data) {
            this.updatePreselected(data);
          }
        })
        .catch(() => {
          this.alert();
        });
    },
    updateApprovalCount(count) {
      this.count = count;

      this.patchEnvironment({
        protected_environment: { required_approval_count: count },
      })
        .then(({ data: { required_approval_count: newCount } } = { data: {} }) => {
          if (newCount) {
            this.count = newCount;
          }
        })
        .catch(() => {
          this.alert();
        });
    },
    patchEnvironment(data) {
      return axios.patch(this.url, data).then((response) => {
        this.$toast.show(i18n.successMessage);
        return response;
      });
    },
    alert() {
      createAlert({
        message: i18n.failureMessage,
        parent: this.parentContainer,
      });
    },
    updatePreselected(items = []) {
      this.preselected = items[ACCESS_LEVELS.DEPLOY].map(
        ({ id, user_id: userId, group_id: groupId, access_level: accessLevel }) => {
          if (userId) {
            return {
              id,
              user_id: userId,
              type: LEVEL_TYPES.USER,
            };
          }

          if (groupId) {
            return {
              id,
              group_id: groupId,
              type: LEVEL_TYPES.GROUP,
            };
          }

          return {
            id,
            access_level: accessLevel,
            type: LEVEL_TYPES.ROLE,
          };
        },
      );
    },
  },
  APPROVAL_COUNT_OPTIONS: [0, 1, 2, 3, 4, 5],
};
</script>

<template>
  <tr>
    <td>
      <span class="ref-name">
        <gl-link v-if="environmentLink" :href="environmentLink">{{ environmentName }}</gl-link>
        <template v-else>{{ environmentName }}</template>
      </span>
    </td>
    <td>
      <access-dropdown
        :access-levels-data="$options.accessLevelsData"
        :access-level="$options.ACCESS_LEVELS.DEPLOY"
        :label="$options.i18n.label"
        :disabled="disabled"
        :preselected-items="preselected"
        @hidden="updatePermissions"
      />
    </td>
    <td class="gl-min-w-20">
      <gl-form-select
        :value="count"
        :options="$options.APPROVAL_COUNT_OPTIONS"
        class="gl-form-input-xs"
        @change="updateApprovalCount"
      />
    </td>
    <td v-if="deleteProtectedEnvironmentLink">
      <gl-button
        :href="deleteProtectedEnvironmentLink"
        variant="danger"
        data-method="delete"
        :data-confirm="confirmUnprotectText"
      >
        {{ s__('ProtectedEnvironment|Unprotect') }}
      </gl-button>
    </td>
  </tr>
</template>
