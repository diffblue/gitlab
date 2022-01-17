import { __, s__ } from '~/locale';

export const i18n = {
  slackErrorMessage: __('Unable to build Slack link.'),
  gitlabLogoAlt: __('GitLab logo'),
  slackLogoAlt: __('Slack logo'),
  title: s__('SlackIntegration|GitLab for Slack'),
  dropdownLabel: s__('SlackIntegration|Select a GitLab project to link with your Slack workspace.'),
  dropdownButtonText: __('Continue'),
  noProjects: __("You don't have any projects available."),
  signInLabel: s__('JiraService|Sign in to GitLab.com to get started.'),
  signInButtonText: __('Sign in to GitLab'),
};
