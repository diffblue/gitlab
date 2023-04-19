<script>
import { uniqueId } from 'lodash';
import { GlLink, GlIcon, GlButton, GlPopover, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import eventHub from '~/invite_members/event_hub';
import { s__ } from '~/locale';
import { LEARN_GITLAB } from 'ee/invite_members/constants';
import { ACTION_LABELS } from '../constants';
import IncludedInTrialIndicator from './included_in_trial_indicator.vue';

export default {
  name: 'LearnGitlabSectionLink',
  components: {
    GlLink,
    GlIcon,
    GlButton,
    GlPopover,
    IncludedInTrialIndicator,
  },
  directives: {
    GlTooltip,
  },
  i18n: {
    contactAdmin: s__('LearnGitlab|Contact your administrator to enable this action.'),
    viewAdminList: s__('LearnGitlab|View administrator list'),
  },
  props: {
    action: {
      required: true,
      type: String,
    },
    value: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      popoverId: uniqueId('contact-admin-'),
    };
  },
  computed: {
    openInNewTab() {
      return ACTION_LABELS[this.action]?.openInNewTab === true || this.value.openInNewTab === true;
    },
    popoverText() {
      return this.value.message || this.$options.i18n.contactAdmin;
    },
  },
  methods: {
    openModalIfIsInviteLink() {
      if (this.action === 'userAdded') {
        eventHub.$emit('openModal', { source: LEARN_GITLAB });
      }
    },
    actionLabelValue(value) {
      return ACTION_LABELS[this.action][value];
    },
  },
};
</script>
<template>
  <div class="gl-mb-4">
    <div class="flex align-items-center">
      <span v-if="value.completed" class="gl-text-green-500">
        <gl-icon name="check-circle-filled" :size="16" data-testid="completed-icon" />
        {{ actionLabelValue('title') }}
        <included-in-trial-indicator v-if="actionLabelValue('trialRequired')" />
      </span>
      <div v-else-if="value.enabled">
        <gl-link
          :target="openInNewTab ? '_blank' : '_self'"
          :href="value.url"
          data-testid="uncompleted-learn-gitlab-link"
          data-qa-selector="uncompleted_learn_gitlab_link"
          data-track-action="click_link"
          :data-track-label="actionLabelValue('trackLabel')"
          @click="openModalIfIsInviteLink"
          >{{ actionLabelValue('title') }}</gl-link
        >

        <included-in-trial-indicator v-if="actionLabelValue('trialRequired')" />
      </div>
      <template v-else>
        <div data-testid="disabled-learn-gitlab-link">{{ actionLabelValue('title') }}</div>
        <gl-button
          :id="popoverId"
          category="tertiary"
          icon="question-o"
          class="ml-auto"
          :aria-label="popoverText"
          size="small"
          data-testid="contact-admin-popover-trigger"
        />
        <gl-popover
          :target="popoverId"
          placement="top"
          triggers="hover focus"
          data-testid="contact-admin-popover"
        >
          <p>{{ popoverText }}</p>
          <gl-link
            :href="value.url"
            class="font-size-inherit"
            data-testid="view-administrator-link-text"
          >
            {{ $options.i18n.viewAdminList }}
          </gl-link>
        </gl-popover>
      </template>
    </div>
  </div>
</template>
