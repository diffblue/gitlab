<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const i18n = {
  title: s__('Workspaces|Develop anywhere'),
  description: s__(`Workspaces|GitLab Workspaces is a powerful collaborative platform that provides a 
                      comprehensive set of tools for software development 
                      teams to manage their entire development lifecycle.`),
  primaryButtonText: s__('Workspaces|Get started with GitLab Workspaces'),
};

export default {
  components: {
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath'],
  computed: {
    workspaceHelpPagePath() {
      return helpPagePath('user/workspace/quick_start/index.md');
    },
  },
  i18n,
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :primary-button-text="$options.i18n.primaryButtonText"
    :primary-button-link="workspaceHelpPagePath"
    :svg-path="emptyStateSvgPath"
  />
</template>
