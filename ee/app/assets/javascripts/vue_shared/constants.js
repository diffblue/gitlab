import { s__, __ } from '~/locale';

export const noneEpic = {
  id: 0,
  title: __('No Epic'),
};

export const placeholderEpic = {
  id: -1,
  title: __('Select epic'),
};

export const SBOM_BANNER_LOCAL_STORAGE_KEY = 'sbom_survey_request';
// NOTE: This string needs to parse to an invalid date. Do not put any characters in between the
// word 'survey' and the number, or else it will parse to a valid date.
export const SBOM_BANNER_CURRENT_ID = 'sbom1';
export const SBOM_SURVEY_LINK = 'https://gitlab.fra1.qualtrics.com/jfe/form/SV_es038rUv1VFqmXk';
export const SBOM_SURVEY_DAYS_TO_ASK_LATER = 7;
export const SBOM_SURVEY_TITLE = s__('SecurityReports|Software and container dependency survey');
export const SBOM_SURVEY_BUTTON_TEXT = s__('SecurityReports|Take survey');
export const SBOM_SURVEY_DESCRIPTION = s__(
  `SecurityReports|The Composition Analysis group is planning significant updates to how we make available the list of software and container dependency information in your projects. Therefore, we ask that you assist us by taking a short -no longer than 5 minute- survey to help align our direction with your needs.`,
);
export const SBOM_SURVEY_TOAST_MESSAGE = s__(
  'SecurityReports|Your feedback is important to us! We will ask again in 7 days.',
);
