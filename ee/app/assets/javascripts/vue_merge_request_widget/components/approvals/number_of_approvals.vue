<script>
import { GlIcon, GlPopover, GlLink, GlSprintf } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlIcon,
    GlPopover,
    GlLink,
    GlSprintf,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    invalidApproversRules: {
      type: Array,
      required: true,
    },
  },
  computed: {
    pendingApprovalsText() {
      if (this.hasInvalidRules) {
        return __('Invalid');
      }
      if (!this.rule.approvalsRequired) {
        return __('Optional');
      }
      return sprintf(__('%{count} of %{total}'), {
        count: this.rule.approvedBy.nodes.length,
        total: this.rule.approvalsRequired,
      });
    },
    hasInvalidRules() {
      return this.invalidApproversRules.some((invalidRule) => invalidRule.id === this.rule.id);
    },
  },
  rulesDocsPath: helpPagePath('user/project/merge_requests/approvals/rules.html', {
    anchor: 'eligible-approvers',
  }),
  settingsDocsPath: helpPagePath('user/project/merge_requests/approvals/settings.html', {
    anchor: 'approval-settings',
  }),
};
</script>

<template>
  <span>
    <span data-testid="approvals-text">{{ pendingApprovalsText }}</span>
    <span v-if="hasInvalidRules" class="gl-display-inline-flex gl-ml-2 js-help">
      <gl-icon
        :id="rule.name"
        name="question-o"
        class="author-link gl-cursor-help"
        :aria-label="__('help')"
        :size="14"
        data-testid="icon2"
      />
      <gl-popover :target="rule.name" placement="top" :title="__('Why is this rule invalid?')">
        {{
          __('This rule is invalid because no one can approve it for one or more of these reasons:')
        }}
        <ul class="gl-my-2 gl-ml-6 gl-pl-0">
          <li>
            <gl-sprintf
              :message="__('It doesn\'t have any %{linkStart}eligible approvers%{linkEnd}.')"
            >
              <template #link="{ content }">
                <gl-link :href="$options.rulesDocsPath" class="gl-font-sm" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf
              :message="
                __(
                  '%{linkStart}Approval settings%{linkEnd} prevent approvals by its eligible approvers.',
                )
              "
            >
              <template #link="{ content }">
                <gl-link :href="$options.settingsDocsPath" class="gl-font-sm" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </li>
        </ul>
        {{ __('Invalid rules are automatically approved to unblock the merge request.') }}
      </gl-popover>
    </span>
  </span>
</template>
