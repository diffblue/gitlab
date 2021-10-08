<script>
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

export const i18n = {
  successMessage: __('Successfully updated the environment.'),
  failureMessage: __('Failed to update environment!'),
};

export default {
  i18n,
  ACCESS_LEVELS,
  accessLevelsData: gon?.deploy_access_levels?.roles ?? [],
  components: {
    AccessDropdown,
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
    label: {
      type: String,
      required: false,
      default: i18n.selectUsers,
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
  },
  data() {
    return {
      preselected: this.preselectedItems,
      selected: null,
    };
  },
  computed: {
    hasChanges() {
      return this.selected.some(({ id, _destroy }) => id === undefined || _destroy);
    },
  },
  methods: {
    updatePermissions(permissions) {
      this.selected = permissions;

      if (!this.hasChanges) {
        return;
      }

      axios
        .patch(this.url, {
          protected_environment: { [`${ACCESS_LEVELS.DEPLOY}_attributes`]: permissions },
        })
        .then(({ data }) => {
          this.$toast.show(i18n.successMessage);
          this.updatePreselected(data);
        })
        .catch(() => {
          createFlash({
            message: i18n.failureMessage,
            parent: this.parentContainer,
          });
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
};
</script>

<template>
  <access-dropdown
    :access-levels-data="$options.accessLevelsData"
    :access-level="$options.ACCESS_LEVELS.DEPLOY"
    :label="label"
    :disabled="disabled"
    :preselected-items="preselected"
    @hidden="updatePermissions"
  />
</template>
