// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';

export default {
  computed: {
    diffFileDiscussions() {
      return this.allDiscussions.filter((d) => !d.isDraft);
    },
  },
  methods: {
    ...mapActions(['toggleDiscussion']),
    clickedToggle(discussion) {
      if (!discussion.isDraft) {
        this.toggleDiscussion({ discussionId: discussion.id });
      }
    },
    toggleText(discussion, index) {
      const count = index + 1;

      return discussion.isDraft ? count - this.diffFileDiscussions.length : count;
    },
  },
};
