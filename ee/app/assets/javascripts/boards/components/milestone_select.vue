<script>
import { GlButton } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions } from 'vuex';
import { s__ } from '~/locale';

import groupMilestonesQuery from '~/sidebar/queries/group_milestones.query.graphql';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';

import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';

import { MilestonesPreset, DONT_FILTER_MILESTONE } from '../constants';

export default {
  MilestonesPreset,
  components: {
    GlButton,
    DropdownWidget,
  },
  inject: ['fullPath', 'isProjectBoard'],
  props: {
    board: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      search: '',
      milestones: [],
      selected: this.board.milestone,
      isEditing: false,
      isDropdownShowing: false,
    };
  },
  apollo: {
    milestones: {
      query() {
        return this.isProjectBoard ? projectMilestonesQuery : groupMilestonesQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          title: this.search,
          first: 20,
        };
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        return data?.workspace?.attributes?.nodes || [];
      },
      error() {
        this.setError({ message: this.$options.i18n.errorSearchingMilestones });
      },
    },
  },
  computed: {
    anyMilestone() {
      return this.selected.title === DONT_FILTER_MILESTONE.title;
    },
    milestoneTitle() {
      return this.selected.title;
    },
    milestoneTitleClass() {
      return this.anyMilestone ? 'gl-text-gray-500' : 'gl-font-weight-bold';
    },
    isLoading() {
      return this.$apollo.queries.milestones.loading;
    },
  },
  created() {
    if (isEmpty(this.board.milestone)) {
      this.selected = DONT_FILTER_MILESTONE;
    }
  },
  methods: {
    ...mapActions(['setError']),
    selectMilestone(milestone) {
      this.selected = milestone;
      this.toggleEdit();
      this.$emit('set-milestone', milestone?.id);
    },
    toggleEdit() {
      if (!this.isEditing && !this.isDropdownShowing) {
        this.isEditing = true;
        this.showDropdown();
      } else {
        this.isEditing = false;
        this.isDropdownShowing = false;
      }
    },
    showDropdown() {
      this.$refs.editDropdown.showDropdown();
      this.isDropdownShowing = true;
    },
    hideDropdown() {
      this.isEditing = false;
    },
    setSearch(search) {
      this.search = search;
    },
  },
  i18n: {
    label: s__('BoardScope|Milestone'),
    errorSearchingMilestones: s__(
      'BoardScope|An error occurred while getting milestones, please try again.',
    ),
    searchMilestones: s__('BoardScope|Search milestones'),
    selectMilestone: s__('BoardScope|Select milestone'),
    edit: s__('BoardScope|Edit'),
  },
};
</script>

<template>
  <div class="block milestone">
    <div class="title gl-mb-3">
      {{ $options.i18n.label }}
      <gl-button
        v-if="canEdit"
        category="tertiary"
        size="small"
        class="edit-link float-right"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div v-if="!isEditing" :class="milestoneTitleClass" data-testid="selected-milestone">
      {{ milestoneTitle }}
    </div>

    <dropdown-widget
      v-show="isEditing"
      ref="editDropdown"
      :select-text="$options.i18n.selectMilestone"
      :search-text="$options.i18n.searchMilestones"
      :preset-options="$options.MilestonesPreset"
      :options="milestones"
      :is-loading="isLoading"
      :selected="selected"
      :search-term="search"
      @hide="hideDropdown"
      @set-option="selectMilestone"
      @set-search="setSearch"
    />
  </div>
</template>
