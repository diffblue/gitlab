<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
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
    groupSettingsDocsPath: helpPagePath('user/project/merge_requests/merge_request_approvals'),
  },
  i18n: {
    groupSettingsHeader: __('Merge request approvals'),
    groupSettingsDescription: __('Define approval settings. %{linkStart}Learn more.%{linkEnd}'),
  },
  labels: GROUP_APPROVAL_SETTINGS_LABELS_I18N,
};
</script>

<template>
  <settings-block :default-expanded="defaultExpanded" data-testid="merge-request-approval-settings">
    <template #title> {{ $options.i18n.groupSettingsHeader }}</template>
    <template #description>
      <gl-sprintf :message="$options.i18n.groupSettingsDescription">
        <template #link="{ content }">
          <gl-link :href="$options.links.groupSettingsDocsPath" target="_blank">{{
            content
          }}</gl-link>
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
