<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  DEBOUNCE_DELAY,
  I18N_GROUP_DROPDOWN_TEXT,
  I18N_GROUP_DROPDOWN_HEADER,
  I18N_ADMIN_DROPDOWN_TEXT,
  I18N_ADMIN_DROPDOWN_HEADER,
  I18N_NO_RESULTS,
  I18N_NO_SUB_GROUPS,
} from '../constants';
import bulkEnableDevopsAdoptionNamespacesMutation from '../graphql/mutations/bulk_enable_devops_adoption_namespaces.mutation.graphql';
import disableDevopsAdoptionNamespaceMutation from '../graphql/mutations/disable_devops_adoption_namespace.mutation.graphql';

export default {
  name: 'DevopsAdoptionAddDropdown',
  i18n: {
    noResults: I18N_NO_RESULTS,
  },
  debounceDelay: DEBOUNCE_DELAY,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    isGroup: {
      default: false,
    },
    groupGid: {
      default: null,
    },
  },
  props: {
    groups: {
      type: Array,
      required: true,
    },
    searchTerm: {
      type: String,
      required: false,
      default: '',
    },
    isLoadingGroups: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasSubgroups: {
      type: Boolean,
      required: false,
      default: false,
    },
    enabledNamespaces: {
      type: Object,
      required: false,
      default: () => ({ nodes: [] }),
    },
  },
  computed: {
    filteredGroupsLength() {
      return this.groups?.length;
    },
    dropdownTitle() {
      return this.isGroup ? I18N_GROUP_DROPDOWN_TEXT : I18N_ADMIN_DROPDOWN_TEXT;
    },
    dropdownHeader() {
      return this.isGroup ? I18N_GROUP_DROPDOWN_HEADER : I18N_ADMIN_DROPDOWN_HEADER;
    },
    tooltipText() {
      return this.isLoadingGroups || this.hasSubgroups ? false : I18N_NO_SUB_GROUPS;
    },
    enabledNamespaceIds() {
      return this.enabledNamespaces.nodes.map((enabledNamespace) =>
        getIdFromGraphQLId(enabledNamespace.namespace.id),
      );
    },
  },
  beforeDestroy() {
    clearTimeout(this.timeout);
    this.timeout = null;
  },
  methods: {
    namespaceIdByGroupId(groupId) {
      return this.enabledNamespaces.nodes?.find(
        (enabledNamespace) => getIdFromGraphQLId(enabledNamespace.namespace.id) === groupId,
      ).id;
    },
    handleGroupSelect(id) {
      const groupEnabled = this.isGroupEnabled(id);

      if (groupEnabled) {
        this.disableGroup(id);
      } else {
        this.enableGroup(id);
      }
    },
    enableGroup(id) {
      this.$apollo
        .mutate({
          mutation: bulkEnableDevopsAdoptionNamespacesMutation,
          variables: {
            namespaceIds: [convertToGraphQLId(TYPENAME_GROUP, id)],
            displayNamespaceId: this.groupGid,
          },
          update: (store, { data }) => {
            const {
              bulkEnableDevopsAdoptionNamespaces: { enabledNamespaces, errors: requestErrors },
            } = data;

            if (!requestErrors.length) this.$emit('enabledNamespacesAdded', enabledNamespaces);
          },
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
    disableGroup(id) {
      const gid = this.namespaceIdByGroupId(id);

      this.$apollo
        .mutate({
          mutation: disableDevopsAdoptionNamespaceMutation,
          variables: {
            id: gid,
          },
          update: () => {
            this.$emit('enabledNamespacesRemoved', gid);
          },
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
    isGroupEnabled(groupId) {
      return this.enabledNamespaceIds.some((namespaceId) => {
        return namespaceId === groupId;
      });
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip="tooltipText"
    :text="dropdownTitle"
    :header-text="dropdownHeader"
    :disabled="!hasSubgroups"
    @show="$emit('trackModalOpenState', true)"
    @hide="$emit('trackModalOpenState', false)"
  >
    <template #header>
      <gl-search-box-by-type
        :debounce="$options.debounceDelay"
        :placeholder="__('Search')"
        @input="$emit('fetchGroups', $event)"
      />
    </template>
    <gl-loading-icon v-if="isLoadingGroups" size="sm" />
    <template v-else>
      <gl-dropdown-item
        v-for="group in groups"
        :key="group.id"
        is-check-item
        :is-checked="isGroupEnabled(group.id)"
        data-testid="group-row"
        @click.native.capture.stop="handleGroupSelect(group.id)"
      >
        {{ group.full_name }}
      </gl-dropdown-item>
      <gl-dropdown-item v-show="!filteredGroupsLength" data-testid="no-results">{{
        $options.i18n.noResults
      }}</gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
