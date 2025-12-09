<?php

/**
 * Matomo - free/libre analytics platform
 *
 * @link    https://matomo.org
 * @license https://www.gnu.org/licenses/gpl-3.0.html GPL v3 or later
 */

namespace Piwik\Updates;

use Piwik\DataAccess\ArchiveTableCreator;
use Piwik\Date;
use Piwik\Updater;
use Piwik\Updater\Migration\Custom;
use Piwik\Updates as PiwikUpdates;

/**
 * Update for version 5.7.0-b1
 */
class Updates_5_7_0_b1 extends PiwikUpdates
{
    public function getMigrations(Updater $updater)
    {
        $migrations = [];

        // ensure the current month's archive_meta_data table exists after update
        $migrations[] = new Custom(function () {
            ArchiveTableCreator::getMetaDataTable(Date::factory('now'));
        }, 'Create current month archive_meta_data table');

        return $migrations;
    }

    public function doUpdate(Updater $updater)
    {
        $updater->executeMigrations(__FILE__, $this->getMigrations($updater));
    }
}
