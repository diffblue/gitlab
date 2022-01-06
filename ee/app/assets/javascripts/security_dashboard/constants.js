import { s__ } from '~/locale';

export const COLLAPSE_SECURITY_REPORTS_SUMMARY_LOCAL_STORAGE_KEY =
  'hide_pipelines_security_reports_summary_details';

export const SURVEY_BANNER_LOCAL_STORAGE_KEY = 'vulnerability_management_survey_request';
export const SURVEY_BANNER_CURRENT_ID = 'survey1';
export const SURVEY_LINK = 'https://gitlab.fra1.qualtrics.com/jfe/form/SV_7UMsVhPbjmwCp1k';
export const SURVEY_DAYS_TO_ASK_LATER = 7;
export const SURVEY_TITLE = s__('SecurityReports|Vulnerability Management feature survey');

export const SURVEY_BUTTON_TEXT = s__('SecurityReports|Take survey');
export const SURVEY_DESCRIPTION = s__(
  `SecurityReports|At GitLab, we're all about iteration and feedback. That's why we are reaching out to customers like you to help guide what we work on this year for Vulnerability Management. We have a lot of exciting ideas and ask that you assist us by taking a short survey %{boldStart}no longer than 10 minutes%{boldEnd} to evaluate a few of our potential features.`,
);

export const SURVEY_TOAST_MESSAGE = s__(
  'SecurityReports|Your feedback is important to us! We will ask again in a week.',
);

export const DEFAULT_SCANNER = 'GitLab';
export const SCANNER_ID_PREFIX = 'gid://gitlab/Vulnerabilities::Scanner/';
