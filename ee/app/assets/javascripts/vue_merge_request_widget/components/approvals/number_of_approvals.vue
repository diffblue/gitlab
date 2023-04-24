<script>
import { GlIcon, GlPopover, GlLink, GlSprintf } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

const i18n = {
  autoApproved: s__('Approvals|Auto approved'),
  actionRequired: s__('Approvals|Action required'),
  optional: __('Optional'),
  help: __('help'),
  countOfTotal: s__('Approvals|%{count} of %{total}'),
  popover: {
    autoApproved: {
      title: s__('Approvals|Rule automatically approved'),
      text: s__(
        'Approvals|It looks like there was a conflict between the rules for approving this Merge Request and the users who were eligible to approve it. As a result, the system has automatically approved it to keep things moving.',
      ),
      suggestion1: s__(
        'Approvals|Verify your %{eligibleApproverLinkStart}eligible approvers%{eligibleApproverLinkEnd} and %{approvalSettingsLinkStart}approval settings%{approvalSettingsLinkEnd} agree with each other.',
      ),
    },
    actionRequired: {
      title: s__('Approvals|Rule cannot be approved'),
      text: s__(
        'Approvals|The number of people who need to approve this is more than those who are allowed to. Please ask the project owner to update %{securityPolicy}.',
      ),
      suggestion1: s__(
        'Approvals|Verify the number of %{linkStart}eligible security approvers%{linkEnd} matches the required approvers for the security policy.',
      ),
      suggestion2: s__(
        'Approvals|Verify your %{linkStart}approval settings%{linkEnd} do not conflict with this rule.',
      ),
    },
  },
};

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
  },
  computed: {
    pendingApprovalsText() {
      if (this.isAutoApproved) {
        return i18n.autoApproved;
      }
      if (this.isActionRequired) {
        return i18n.actionRequired;
      }
      if (!this.rule.approvalsRequired) {
        return i18n.optional;
      }
      return sprintf(i18n.countOfTotal, {
        count: this.rule.approvedBy.nodes.length,
        total: this.rule.approvalsRequired,
      });
    },
    hasInvalidRules() {
      return this.rule.invalid;
    },
    isAutoApproved() {
      return this.hasInvalidRules && this.rule.allowMergeWhenInvalid;
    },
    isActionRequired() {
      return this.hasInvalidRules && !this.rule.allowMergeWhenInvalid;
    },
    invalidRulesClasses() {
      return { 'text-danger': this.isActionRequired, 'text-muted': this.isAutoApproved };
    },
  },
  i18n,
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
    <span v-if="hasInvalidRules" class="vertical-align-text-top js-help">
      <gl-icon
        :id="rule.name"
        name="status_warning"
        class="gl-cursor-help"
        :class="invalidRulesClasses"
        :aria-label="$options.i18n.help"
        :size="14"
      />
      <gl-popover
        v-if="isAutoApproved"
        :target="rule.name"
        placement="top"
        :title="$options.i18n.popover.autoApproved.title"
        data-testid="popover-auto-approved"
      >
        {{ $options.i18n.popover.autoApproved.text }}
        <ul class="gl-my-2 gl-ml-6 gl-pl-0">
          <li>
            <gl-sprintf :message="$options.i18n.popover.autoApproved.suggestion1">
              <template #eligibleApproverLink="{ content }">
                <gl-link :href="$options.rulesDocsPath" class="gl-font-sm" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
              <template #approvalSettingsLink="{ content }">
                <gl-link :href="$options.settingsDocsPath" class="gl-font-sm" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </li>
        </ul>
      </gl-popover>
      <gl-popover
        v-if="isActionRequired"
        :target="rule.name"
        placement="top"
        :title="$options.i18n.popover.actionRequired.title"
        data-testid="popover-action-required"
      >
        <gl-sprintf :message="$options.i18n.popover.actionRequired.text">
          <template #securityPolicy>{{ rule.name }}</template>
        </gl-sprintf>
        <ul class="gl-my-2 gl-ml-6 gl-pl-0">
          <li>
            <gl-sprintf :message="$options.i18n.popover.actionRequired.suggestion1">
              <template #link="{ content }">
                <gl-link :href="$options.rulesDocsPath" class="gl-font-sm" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf :message="$options.i18n.popover.actionRequired.suggestion2">
              <template #link="{ content }">
                <gl-link :href="$options.settingsDocsPath" class="gl-font-sm" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </li>
        </ul>
      </gl-popover>
    </span>
    <span data-testid="approvals-text" :class="invalidRulesClasses">
      {{ pendingApprovalsText }}
    </span>
  </span>
</template>
