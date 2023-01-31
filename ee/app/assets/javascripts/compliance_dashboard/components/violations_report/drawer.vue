<script>
import { GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { COMPLIANCE_DRAWER_CONTAINER_CLASS } from '../../constants';
import BranchPath from './drawer_sections/branch_path.vue';
import Committers from './drawer_sections/committers.vue';
import MergedBy from './drawer_sections/merged_by.vue';
import Project from './drawer_sections/project.vue';
import Reference from './drawer_sections/reference.vue';
import Reviewers from './drawer_sections/reviewers.vue';

export default {
  components: {
    BranchPath,
    Committers,
    GlDrawer,
    MergedBy,
    Reference,
    Reviewers,
    Project,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    project: {
      type: Object,
      required: true,
    },
    showDrawer: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasBranchDetails() {
      return this.mergeRequest.sourceBranch && this.mergeRequest.targetBranch;
    },
    drawerHeaderHeight() {
      return getContentWrapperHeight(COMPLIANCE_DRAWER_CONTAINER_CLASS);
    },
  },
  DRAWER_Z_INDEX,
};
</script>
<template>
  <gl-drawer
    :open="showDrawer"
    :header-height="drawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template #title>
      <h4 data-testid="dashboard-drawer-title">{{ mergeRequest.title }}</h4>
    </template>
    <template v-if="showDrawer" #default>
      <project
        :avatar-url="project.avatarUrl"
        :compliance-framework="project.complianceFramework"
        :name="project.name"
        :url="project.webUrl"
      />
      <reference :path="mergeRequest.webUrl" :reference="mergeRequest.ref" />
      <branch-path
        v-if="hasBranchDetails"
        :source-branch="mergeRequest.sourceBranch"
        :source-branch-uri="mergeRequest.sourceBranchUri"
        :target-branch="mergeRequest.targetBranch"
        :target-branch-uri="mergeRequest.targetBranchUri"
      />
      <committers :committers="mergeRequest.committers" />
      <reviewers
        :approvers="mergeRequest.approvedByUsers"
        :commenters="mergeRequest.participants"
      />
      <merged-by :merged-by="mergeRequest.mergeUser" />
    </template>
  </gl-drawer>
</template>
