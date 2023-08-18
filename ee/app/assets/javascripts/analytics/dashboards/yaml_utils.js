import { parse } from 'yaml';
import Api from '~/api';
import { YAML_CONFIG_PATH } from './constants';

/**
 * Fetches and returns the parsed YAML config file.
 *
 * @param {Number} projectId - ID of the project that contains the YAML config file
 * @returns {Object} The parsed YAML config file
 */
export const fetchYamlConfig = async (projectId) => {
  if (!projectId) return null;

  try {
    const { data } = await Api.getRawFile(projectId, YAML_CONFIG_PATH);
    return parse(data);
  } catch {
    return null;
  }
};
