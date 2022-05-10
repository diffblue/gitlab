<script>
import { GlTooltipDirective, GlButton, GlButtonGroup } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import { __ } from '~/locale';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlButtonGroup,
  },
  mixins: [discussionNavigation],
  props: {
    blocksMerge: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters([
      'getUserData',
      'getNoteableData',
      'resolvableDiscussionsCount',
      'unresolvedDiscussionsCount',
      'allResolvableDiscussions',
    ]),
    isLoggedIn() {
      return this.getUserData.id;
    },
    allResolved() {
      return this.unresolvedDiscussionsCount === 0;
    },
    resolveAllDiscussionsIssuePath() {
      return this.getNoteableData.create_issue_to_resolve_discussions_path;
    },
    allExpanded() {
      return this.allResolvableDiscussions.every((discussion) => discussion.expanded);
    },
    toggleThreadsLabel() {
      return this.allExpanded ? __('Collapse all threads') : __('Expand all threads');
    },
  },
  methods: {
    ...mapActions(['setExpandDiscussions']),
    handleExpandDiscussions() {
      this.setExpandDiscussions({
        discussionIds: this.allResolvableDiscussions.map((discussion) => discussion.id),
        expanded: !this.allExpanded,
      });
    },
  },
};
</script>

<template>
  <div
    v-if="resolvableDiscussionsCount > 0"
    ref="discussionCounter"
    class="gl-display-flex discussions-counter"
  >
    <div
      class="gl-display-flex gl-align-items-center gl-px-4 gl-rounded-base gl-mr-3"
      :class="{
        'gl-bg-orange-50': blocksMerge,
        'gl-bg-gray-50': !blocksMerge,
      }"
      data-testid="discussions-counter-text"
    >
      <template v-if="allResolved">
        {{ __('All threads resolved') }}
      </template>
      <template v-else>
        {{ n__('%d unresolved thread', '%d unresolved threads', unresolvedDiscussionsCount) }}
      </template>
    </div>
    <gl-button-group>
      <gl-button
        v-if="isLoggedIn && !allResolved"
        v-gl-tooltip
        :title="__('Jump to next unresolved thread')"
        :aria-label="__('Jump to next unresolved thread')"
        class="discussion-next-btn"
        data-track-action="click_button"
        data-track-label="mr_next_unresolved_thread"
        data-track-property="click_next_unresolved_thread_top"
        icon="comment-next"
        @click="jumpToNextDiscussion"
      />
      <gl-button
        v-gl-tooltip
        :title="toggleThreadsLabel"
        :aria-label="toggleThreadsLabel"
        class="toggle-all-discussions-btn"
        :icon="allExpanded ? 'collapse' : 'expand'"
        @click="handleExpandDiscussions"
      />
    </gl-button-group>
  </div>
</template>
