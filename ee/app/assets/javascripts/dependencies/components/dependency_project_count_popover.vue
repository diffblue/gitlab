<script>
import { GlSprintf, GlLink, GlButton, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlSprintf,
    GlLink,
    GlButton,
    GlPopover,
  },
  props: {
    targetId: { type: String, required: true },
    targetText: { type: String, required: true },
  },
  GROUP_LEVEL_DEPENDENCY_LIST_DOC: helpPagePath('user/application_security/dependency_list/index', {
    anchor: 'view-a-groups-dependencies',
  }),
  i18n: {
    description: s__(
      'Dependencies|This group exceeds the maximum number of sub-groups of 600. We cannot accurately display a project list at this time. Please access a sub-group dependency list to view this information or see the %{linkStart}dependency list help %{linkEnd} page to learn more.',
    ),
    title: s__('Dependencies|Project list unavailable'),
  },
};
</script>

<template>
  <div>
    <gl-button :id="targetId" variant="link" class="gl-hover-text-decoration-none">{{
      targetText
    }}</gl-button>
    <gl-popover
      :target="targetId"
      :title="$options.i18n.title"
      triggers="click"
      :show-close-button="true"
      container="viewport"
    >
      <gl-sprintf :message="$options.i18n.description">
        <template #link="{ content }">
          <gl-link :href="$options.GROUP_LEVEL_DEPENDENCY_LIST_DOC" class="gl-font-sm">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-popover>
  </div>
</template>
