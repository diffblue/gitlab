import { s__, sprintf } from '~/locale';

/**
 * Creates the notification text to show the user regarding projects that failed to get added
 * to the dashboard
 *
 * @param {Array} invalidProjects all the projects that failed to be added
 * @returns {String} the invalid projects formated in a user-friendly way
 */
export const createInvalidProjectMessage = (invalidProjects) => {
  const [firstProject, secondProject, ...rest] = invalidProjects.map((project) => project.name);
  const translationValues = {
    firstProject,
    secondProject,
    rest: rest.join(', '),
  };

  if (rest.length > 0) {
    return sprintf(
      s__('SecurityReports|%{firstProject}, %{secondProject}, and %{rest}'),
      translationValues,
    );
  }
  if (secondProject) {
    return sprintf(s__('SecurityReports|%{firstProject} and %{secondProject}'), translationValues);
  }
  return firstProject;
};
