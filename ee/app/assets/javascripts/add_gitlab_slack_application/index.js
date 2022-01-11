import Vue from 'vue';
import AddGitlabSlackApplication from './components/add_gitlab_slack_application.vue';

export default () => {
  const el = document.querySelector('.js-add-gitlab-slack-application');

  if (!el) return null;

  const {
    projects,
    isSignedIn,
    gitlabForSlackGifPath,
    signInPath,
    slackLinkPath,
    gitlabLogoPath,
    slackLogoPath,
    docsPath,
  } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(AddGitlabSlackApplication, {
        props: {
          projects: JSON.parse(projects),
          isSignedIn,
          gitlabForSlackGifPath,
          signInPath,
          slackLinkPath,
          gitlabLogoPath,
          slackLogoPath,
          docsPath,
        },
      });
    },
  });
};
