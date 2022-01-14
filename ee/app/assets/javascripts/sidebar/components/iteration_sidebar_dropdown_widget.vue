<script>
import {
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlIcon,
  GlLink,
} from '@gitlab/ui';
import SidebarDropdownWidget from 'ee/sidebar/components/sidebar_dropdown_widget.vue';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import {
  getIterationPeriod,
  getIterationTitle,
  groupByIterationCadences,
} from 'ee/iterations/utils';
import { IssuableType } from '~/issues/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { IssuableAttributeType } from '../constants';

export default {
  issuableAttribute: IssuableAttributeType.Iteration,
  components: {
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlIcon,
    GlLink,
    SidebarDropdownWidget,
    IterationTitle,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    attrWorkspacePath: {
      required: true,
      type: String,
    },
    iid: {
      required: true,
      type: String,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return value === IssuableType.Issue;
      },
    },
    workspacePath: {
      required: true,
      type: String,
    },
  },
  methods: {
    getCadenceTitle(currentIteration) {
      return currentIteration?.iterationCadence?.title;
    },
    groupByIterationCadences,
    getIterationPeriod,
    getIterationTitle,
  },
};
</script>

<template>
  <sidebar-dropdown-widget
    :attr-workspace-path="attrWorkspacePath"
    :iid="iid"
    :issuable-attribute="$options.issuableAttribute"
    :issuable-type="issuableType"
    :workspace-path="workspacePath"
  >
    <template #value="{ attributeUrl, currentAttribute }">
      <p v-if="glFeatures.iterationCadences" class="gl-font-weight-bold gl-line-height-20 gl-m-0">
        {{ getCadenceTitle(currentAttribute) }}
      </p>
      <gl-link
        class="gl-text-gray-900! gl-line-height-20"
        :href="attributeUrl"
        data-qa-selector="iteration_link"
      >
        <div>
          <gl-icon name="iteration" class="gl-mr-1" />
          {{ getIterationPeriod(currentAttribute) }}
        </div>
        <iteration-title v-if="getIterationTitle(currentAttribute)">{{
          getIterationTitle(currentAttribute)
        }}</iteration-title>
      </gl-link>
    </template>
    <template #list="{ attributesList = [], isAttributeChecked, updateAttribute }">
      <template v-for="(cadence, index) in groupByIterationCadences(attributesList)">
        <gl-dropdown-divider v-if="index !== 0 && glFeatures.iterationCadences" :key="index" />
        <gl-dropdown-section-header
          v-if="glFeatures.iterationCadences"
          :key="cadence.title"
          data-testid="cadence-title"
        >
          {{ cadence.title }}
        </gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="iteration in cadence.iterations"
          :key="iteration.id"
          :is-check-item="true"
          :is-checked="isAttributeChecked(iteration.id)"
          :data-testid="`${$options.issuableAttribute}-items`"
          @click="updateAttribute(iteration.id)"
        >
          {{ iteration.period }}
          <iteration-title v-if="getIterationTitle(iteration)">{{
            getIterationTitle(iteration)
          }}</iteration-title>
        </gl-dropdown-item>
      </template>
    </template>
  </sidebar-dropdown-widget>
</template>
