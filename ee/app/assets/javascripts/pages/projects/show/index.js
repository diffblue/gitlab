import '~/pages/projects/show/index';
import { initSastEntryPointsExperiment } from 'ee/projects/sast_entry_points_experiment';
import initVueAlerts from '~/vue_alerts';

initVueAlerts();
initSastEntryPointsExperiment();
