<script>
import { GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createCveIdRequestIssueBody } from '~/helpers/cve_id_request_helper';
import { CVE_ID_REQUEST_SIDEBAR_I18N } from '../../constants';

export default {
  i18n: {
    ...CVE_ID_REQUEST_SIDEBAR_I18N,
  },

  components: {
    GlIcon,
    GlLink,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  inject: {
    iid: {
      required: true,
      type: String,
    },
    fullPath: {
      required: true,
      type: String,
    },
  },

  data() {
    return {
      showHelp: false,
    };
  },

  computed: {
    ...mapState({ confidential: (state) => state.noteableData.confidential }),
    helpHref() {
      return helpPagePath('user/application_security/cve_id_request');
    },
    showHelpState() {
      return Boolean(this.showHelp);
    },
    tooltipTitle() {
      return this.$options.i18n.description;
    },
    newCveIdRequestUrl() {
      const currUrl = new URL(window.location.href);
      const newUrl = new URL(currUrl.origin);
      newUrl.pathname = '/gitlab-org/cves/-/issues/new';

      const params = {
        'issue[confidential]': 'true',
        // eslint-disable-next-line @gitlab/require-i18n-strings
        'issue[title]': `CVE ID Request - ${this.fullPath}`,
        'issue[description]': createCveIdRequestIssueBody(this.fullPath, this.iid),
      };
      Object.keys(params).forEach((k) => newUrl.searchParams.append(k, params[k]));

      return newUrl.toString();
    },
  },

  methods: {
    toggleHelpState(show) {
      this.showHelp = show;
    },
  },
};
</script>

<template>
  <div v-if="confidential" class="sidebar-contained-width cve-id-request gl-pb-0 gl-border-b-0">
    <div
      v-gl-tooltip.viewport.left
      :title="tooltipTitle"
      class="sidebar-collapsed-icon"
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
    >
      <gl-icon name="bug" class="sidebar-item-icon is-active" />
    </div>

    <div class="hide-collapsed">
      {{ $options.i18n.action }}
      <div
        v-if="!showHelpState"
        class="help-button float-right"
        data-testid="help-button"
        @click="toggleHelpState(true)"
      >
        <gl-icon name="question-o" />
      </div>
      <div
        v-else
        class="close-help-button float-right"
        data-testid="close-help-button"
        @click="toggleHelpState(false)"
      >
        <gl-icon name="close" />
      </div>

      <div class="gl-mt-5">
        <gl-link
          :href="newCveIdRequestUrl"
          target="_blank"
          class="btn btn-default btn-block js-cve-id-request-button"
          data-testid="request-button"
          data-qa-selector="cve_id_request_button"
          >{{ $options.i18n.createRequest }}</gl-link
        >
      </div>

      <div class="hide-collapsed">
        <transition name="help-state-toggle">
          <div v-if="showHelpState" class="cve-id-request-help-state" data-testid="help-state">
            <h4>{{ $options.i18n.whyRequest }}</h4>
            <p>
              {{ $options.i18n.whyText1 }}
            </p>

            <p>
              {{ $options.i18n.whyText2 }}
            </p>

            <div>
              <gl-link
                :href="helpHref"
                target="_blank"
                class="btn btn-default js-cve-id-request-learn-more-link"
                data-qa-selector="cve_id_request_learn_more_link"
                >{{ $options.i18n.learnMore }}</gl-link
              >
            </div>
          </div>
        </transition>
      </div>
    </div>
  </div>
</template>
