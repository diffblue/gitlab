import { s__ } from '~/locale';

export const EXPERIMENT_NAME = 'sast_entry_points';

export const COOKIE_NAME = 'sast_entry_point_dismissed';

export const POPOVER_TARGET = '.js-sast-entry-point';

export const I18N = {
  title: s__('SastEntryPoints|Catch your security vulnerabilities ahead of time!'),
  bodyText: s__(
    'SastEntryPoints|GitLab can scan your code for security vulnerabilities. Static Application Security Testing (SAST) helps you worry less and build more.',
  ),
  buttonText: s__('SastEntryPoints|Learn more.'),
  linkText: s__('SastEntryPoints|How do I set up SAST?'),
};
