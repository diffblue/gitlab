<script>
import { GlDropdown, GlDropdownDivider, GlDropdownSectionHeader, GlDropdownItem } from '@gitlab/ui';
import { mapState } from 'vuex';

import { s__, __ } from '~/locale';

const issueActionItems = [
  {
    title: __('Add a new issue'),
    eventName: 'showCreateIssueForm',
  },
  {
    title: __('Add an existing issue'),
    eventName: 'showAddIssueForm',
  },
];

const epicActionItems = [
  {
    title: s__('Epics|Add a new epic'),
    eventName: 'showCreateEpicForm',
  },
  {
    title: s__('Epics|Add an existing epic'),
    eventName: 'showAddEpicForm',
  },
];

export default {
  epicActionItems,
  issueActionItems,
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownItem,
  },
  props: {
    allowSubEpics: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['parentItem']),
    showEpicSection() {
      return this.allowSubEpics && this.parentItem.userPermissions.canAdminRelation;
    },
  },
  methods: {
    change({ eventName }) {
      this.$emit(eventName);
    },
  },
};
</script>

<template>
  <gl-dropdown :text="__('Add')" data-qa-selector="epic_issue_actions_split_button" right>
    <gl-dropdown-section-header>{{ __('Issue') }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="item in $options.issueActionItems"
      :key="item.eventName"
      @click="change(item)"
    >
      {{ item.title }}
    </gl-dropdown-item>

    <template v-if="showEpicSection">
      <gl-dropdown-divider />
      <gl-dropdown-section-header>{{ __('Epic') }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="item in $options.epicActionItems"
        :key="item.eventName"
        @click="change(item)"
      >
        {{ item.title }}
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
