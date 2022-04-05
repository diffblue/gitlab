<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import { GROUP_APPROVAL_SETTINGS_LABELS_I18N } from '../../constants';
import ApprovalSettings from '../approval_settings.vue';

export default {
  name: 'GroupApprovalSettingsApp',
  components: {
    ApprovalSettings,
    GlSprintf,
    GlLink,
    SettingsBlock,
  },
  props: {
    defaultExpanded: {
      type: Boolean,
      required: true,
    },
    approvalSettingsPath: {
      type: String,
      required: true,
    },
  },
  links: {
    groupSettingsDocsPath: helpPagePath('user/project/merge_requests/approvals/index.md'),
    separationOfDutiesDocsPath: helpPagePath('user/compliance/compliance_report/index', {
      anchor: 'separation-of-duties',
    }),
  },
  i18n: {
    groupSettingsHeader: __('Merge request approvals'),
    groupSettingsDescription: s__(
      'MergeRequestApprovals|Enforce %{separationLinkStart}separation of duties%{separationLinkEnd} for all projects. %{learnLinkStart}Learn more.%{learnLinkEnd}',
    ),
  },
  labels: GROUP_APPROVAL_SETTINGS_LABELS_I18N,
};
</script>

<template>
  <settings-block :default-expanded="defaultExpanded" data-testid="merge-request-approval-settings">
    <template #title> {{ $options.i18n.groupSettingsHeader }}</template>
    <template #description>
      <gl-sprintf :message="$options.i18n.groupSettingsDescription">
        <template #separationLink="{ content }">
          <gl-link
            data-testid="group-settings-description"
            :href="$options.links.separationOfDutiesDocsPath"
            target="_blank"
            >{{ content }}</gl-link
          >
        </template>
        <template #learnLink="{ content }">
          <gl-link
            data-testid="group-settings-learn-more"
            :href="$options.links.groupSettingsDocsPath"
            target="_blank"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </template>
    <template #default>
      <approval-settings
        :approval-settings-path="approvalSettingsPath"
        :settings-labels="$options.labels"
      />
    </template>
  </settings-block>
</template>
