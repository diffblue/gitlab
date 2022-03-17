<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { PROJECT_COMPLIANCE_FRAMEWORK_I18N } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  props: {
    groupName: {
      type: String,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
    addFrameworkPath: {
      type: String,
      required: false,
      default: '',
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    canEdit() {
      return this.addFrameworkPath !== '';
    },
    description() {
      return this.canEdit
        ? PROJECT_COMPLIANCE_FRAMEWORK_I18N.ownerDescription
        : PROJECT_COMPLIANCE_FRAMEWORK_I18N.maintainerDescription;
    },
    buttonText() {
      return this.canEdit
        ? sprintf(PROJECT_COMPLIANCE_FRAMEWORK_I18N.buttonText, { groupName: this.groupName })
        : null;
    },
    buttonLink() {
      return this.canEdit ? this.addFrameworkPath : null;
    },
  },
  i18n: {
    title: PROJECT_COMPLIANCE_FRAMEWORK_I18N.title,
  },
};
</script>

<template>
  <gl-empty-state
    :description="$options.i18n.description"
    :primary-button-text="buttonText"
    :primary-button-link="buttonLink"
    :svg-path="emptyStateSvgPath"
    :svg-height="100"
    compact
  >
    <template #title>
      <h5 class="gl-mt-0">{{ $options.i18n.title }}</h5>
    </template>
    <template #description>
      <gl-sprintf :message="description">
        <template #link>
          <gl-link :href="groupPath">{{ groupName }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
