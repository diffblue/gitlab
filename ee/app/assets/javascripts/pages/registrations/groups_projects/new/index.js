/* eslint-disable no-new */

import mountComponents from 'ee/registrations/groups_projects/new';
import Group from '~/group';
import { trackCombinedGroupProjectForm, trackProjectImport } from '~/google_tag_manager';

new Group();
mountComponents();
trackCombinedGroupProjectForm();
trackProjectImport();
