<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ROUTES } from '../../constants';

export const i18n = {
  title: s__('Workspaces|Develop anywhere'),
  description: s__(`Workspaces|GitLab Workspaces is a powerful collaborative platform that provides a
                      comprehensive set of tools for software development
                      teams to manage their entire development lifecycle.`),
  primaryButtonText: s__('Workspaces|New workspace'),
};

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  inject: ['emptyStateSvgPath'],
  i18n,
  ROUTES,
};
</script>

<template>
  <div>
    <gl-empty-state
      :title="$options.i18n.title"
      :description="$options.i18n.description"
      :svg-path="emptyStateSvgPath"
      :svg-height="150"
    >
      <template #actions>
        <gl-button
          variant="confirm"
          class="gl-mb-3 gl-mx-2"
          :to="$options.ROUTES.create"
          data-qa-selector="empty_new_workspace_button"
          >{{ $options.i18n.primaryButtonText }}</gl-button
        >
      </template>
    </gl-empty-state>
  </div>
</template>
