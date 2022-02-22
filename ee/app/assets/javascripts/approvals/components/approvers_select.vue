<script>
import $ from 'jquery';
import { escape, debounce } from 'lodash';
import Api from 'ee/api';
import { renderAvatar } from '~/helpers/avatar_helper';
import { loadCSSFile } from '~/lib/utils/css_utils';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TYPE_USER, TYPE_GROUP } from '../constants';

function addType(type) {
  return (items) => items.map((obj) => Object.assign(obj, { type }));
}

function formatSelection(group) {
  return escape(group.full_name || group.name);
}

function formatResultUser(result) {
  const { name, username } = result;
  const avatar = renderAvatar(result, { sizeClass: 's40' });

  return `
    <div class="user-result">
      <div class="user-image">
        ${avatar}
      </div>
      <div class="user-info">
        <div class="user-name">${escape(name)}</div>
        <div class="user-username">@${escape(username)}</div>
      </div>
    </div>
  `;
}

function formatResultGroup(result) {
  const { full_name: fullName, full_path: fullPath } = result;
  const avatar = renderAvatar(result, { sizeClass: 's40' });

  return `
    <div class="user-result group-result">
      <div class="group-image">
        ${avatar}
      </div>
      <div class="group-info">
        <div class="group-name">${escape(fullName)}</div>
        <div class="group-path">${escape(fullPath)}</div>
      </div>
    </div>
  `;
}

function formatResult(result) {
  return result.type === TYPE_USER ? formatResultUser(result) : formatResultGroup(result);
}

export default {
  mixins: [glFeatureFlagsMixin()],
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    projectId: {
      type: String,
      required: true,
    },
    skipUserIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    skipGroupIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    isInvalid: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isFeatureEnabled() {
      return this.glFeatures.permitAllSharedGroupsForApproval;
    },
  },
  watch: {
    value(val) {
      if (val.length > 0) {
        this.clear();
      }
    },
    isInvalid(val) {
      const $container = $(this.$refs.input).select2('container');

      if (val) {
        $container.addClass('is-invalid');
      } else {
        $container.removeClass('is-invalid');
      }
    },
  },
  mounted() {
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        // eslint-disable-next-line promise/no-nesting
        loadCSSFile(gon.select2_css_path)
          .then(() => {
            $(this.$refs.input)
              .select2({
                placeholder: __('Search users or groups'),
                minimumInputLength: 0,
                multiple: true,
                closeOnSelect: false,
                formatResult,
                formatSelection,
                query: debounce(({ term, callback }) => {
                  // eslint-disable-next-line promise/no-nesting
                  return this.fetchGroupsAndUsers(term).then(callback);
                }, 250),
                id: ({ type, id }) => `${type}${id}`,
              })
              .on('change', (e) => this.onChange(e));
          })
          .catch(() => {});
      })
      .catch(() => {});
  },
  beforeDestroy() {
    $(this.$refs.input).select2('destroy');
  },
  methods: {
    fetchGroupsAndUsers(term) {
      const groupsAsync = this.fetchGroups(term).then(addType(TYPE_GROUP));
      const usersAsync = this.fetchUsers(term).then(addType(TYPE_USER));

      return Promise.all([groupsAsync, usersAsync])
        .then(([groups, users]) => groups.concat(users))
        .then((results) => ({ results }));
    },
    fetchGroups(term) {
      if (this.isFeatureEnabled) {
        const hasTerm = term.trim().length > 0;
        const DEVELOPER_ACCESS_LEVEL = 30;

        return Api.projectGroups(this.projectId, {
          skip_groups: this.skipGroupIds,
          ...(hasTerm ? { search: term } : {}),
          with_shared: true,
          shared_visible_only: !this.isFeatureEnabled,
          shared_min_access_level: DEVELOPER_ACCESS_LEVEL,
        });
      }

      // Don't includeAll when search is empty. Otherwise, the user could get a lot of garbage choices.
      // https://gitlab.com/gitlab-org/gitlab/issues/11566
      const includeAll = term.trim().length > 0;

      return Api.groups(term, {
        skip_groups: this.skipGroupIds,
        all_available: includeAll,
      });
    },
    fetchUsers(term) {
      return Api.projectUsers(this.projectId, term, {
        skip_users: this.skipUserIds,
      });
    },
    onChange() {
      // call data instead of val to get array of objects
      const value = $(this.$refs.input).select2('data');

      this.$emit('input', value);
    },
    clear() {
      $(this.$refs.input).select2('data', []);
    },
  },
};
</script>

<template>
  <input ref="input" name="members" type="hidden" />
</template>
