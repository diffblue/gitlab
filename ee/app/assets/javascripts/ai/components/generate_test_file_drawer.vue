<script>
import { GlDrawer, GlBadge, GlSkeletonLoader, GlAlert, GlLink } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import testFileGeneratorMutation from '../graphql/test_file_generator.mutation.graphql';

export default {
  apollo: {
    $subscribe: {
      testFile: {
        query: aiResponseSubscription,
        variables() {
          return {
            resourceId: this.resourceId,
            userId: convertToGraphQLId('User', window.gon.current_user_id), // eslint-disable-line @gitlab/require-i18n-strings
          };
        },
        skip() {
          return !this.opened;
        },
        result({ data }) {
          const responseBody = data.aiCompletionResponse?.responseBody;

          if (responseBody) {
            const codeBlockRegex = /<pre(.*)><code>(.*)<\/code><\/pre>/gm;
            const codeBlock = codeBlockRegex.exec(responseBody.replaceAll('\n', '\\n'));

            if (codeBlock) {
              this.generatedTest = codeBlock[0].replaceAll('\\n', '\n');
              this.state = '';
            } else {
              this.state = 'unable';
            }
          }
        },
      },
    },
  },
  directives: { SafeHtml },
  components: {
    GlDrawer,
    GlBadge,
    GlSkeletonLoader,
    GlAlert,
    GlLink,
    UserFeedback,
  },
  props: {
    resourceId: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      opened: false,
      state: '',
      generatedTest: '',
    };
  },
  computed: {
    drawerHeightOffset() {
      return getContentWrapperHeight('.content-wrapper');
    },
  },
  watch: {
    filePath: {
      handler(newVal) {
        this.opened = Boolean(newVal);

        if (this.opened) {
          this.triggerMutation();
        } else {
          this.generatedTest = '';
          this.state = '';
        }
      },
      immediate: true,
    },
  },
  methods: {
    triggerMutation() {
      this.state = 'loading';

      this.$apollo.mutate({
        mutation: testFileGeneratorMutation,
        variables: {
          resourceId: this.resourceId,
          filePath: this.filePath,
        },
      });
    },
  },
  DRAWER_Z_INDEX,
  feedback: {
    eventName: 'generate_test_file_merge_request',
    link: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408995',
  },
};
</script>

<template>
  <gl-drawer
    :open="opened"
    :header-height="drawerHeightOffset"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template #title>
      <div class="gl-display-flex">
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">
          {{ __('AI-generated test file') }}
        </h2>
        <div>
          <gl-badge variant="info" size="sm" class="gl-ml-3 gl-mt-2">{{
            __('Experiment')
          }}</gl-badge>
        </div>
      </div>
    </template>
    <div>
      <div class="markdown-code-block gl-relative">
        <div
          v-if="state === 'loading'"
          class="gl-border-1 gl-border-gray-100 gl-border-solid gl-p-4 gl-rounded-base gl-bg-gray-10"
          data-testid="generate-test-loading-state"
        >
          <gl-skeleton-loader :lines="4" />
        </div>
        <gl-alert v-else-if="state === 'unable'" :dismissible="false">
          {{ __('Unable to generate tests for specified file.') }}
        </gl-alert>
        <template v-else>
          <div class="gl-relative markdown-code-block js-markdown-code">
            <span v-safe-html="generatedTest" data-testid="generate-test-code"></span>
            <copy-code />
          </div>
          <user-feedback :event-name="$options.feedback.eventName" />
          <p>
            {{ __('AI generated this test') }}
            &middot;
            <gl-link :href="$options.feedback.link" target="_blank">{{
              __('Leave feedback')
            }}</gl-link>
          </p>
        </template>
      </div>
    </div>
  </gl-drawer>
</template>
