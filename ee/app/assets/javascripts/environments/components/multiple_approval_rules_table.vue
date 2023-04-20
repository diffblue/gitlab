<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlLink,
  GlTableLite,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';

const accessLevelDisplay = {
  MAINTAINER: s__('DeploymentApprovals|Maintainers'),
  DEVELOPER: s__('DeploymentApprovals|Developers + Maintainers'),
};

export default {
  name: 'MultipleApprovalRulesTable',
  components: {
    GlAvatar,
    GlAvatarLink,
    GlLink,
    GlTableLite,
  },
  directives: {
    GlTooltip,
  },
  props: {
    rules: {
      required: true,
      type: Array,
    },
  },
  fields: [
    {
      key: 'approvers',
      label: s__('DeploymentApprovals|Approvers'),
    },
    { key: 'approvals', label: s__('DeploymentApprovals|Approvals') },
    { key: 'approvedBy', label: s__('DeploymentApprovals|Approved By') },
  ],
  computed: {
    items() {
      return this.rules.map((rule) => ({
        approvers: this.getRuleName(rule),
        approvals: `${rule.approvedCount}/${rule.requiredApprovals}`,
        approvedBy: rule.approvals,
      }));
    },
  },
  methods: {
    getRuleName(rule) {
      if (rule.group) {
        return { name: rule.group.name, link: rule.group.webUrl };
      } else if (rule.user) {
        return { name: rule.user.name, link: rule.user.webUrl };
      }

      return { name: accessLevelDisplay[rule.accessLevel.stringValue] };
    },
  },
};
</script>
<template>
  <gl-table-lite :fields="$options.fields" :items="items">
    <template #cell(approvers)="{ value }">
      <gl-link v-if="value.link" :href="value.link">{{ value.name }}</gl-link>
      <span v-else>{{ value.name }}</span>
    </template>
    <template #cell(approvedBy)="{ value }">
      <gl-avatar-link
        v-for="approval in value"
        :key="approval.user.id"
        v-gl-tooltip
        :href="approval.user.webUrl"
        :title="approval.user.name"
      >
        <gl-avatar :src="approval.user.avatarUrl" :size="24" />
      </gl-avatar-link>
    </template>
  </gl-table-lite>
</template>
