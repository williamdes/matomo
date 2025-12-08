<?php

/**
 * Matomo - free/libre analytics platform
 *
 * @link    https://matomo.org
 * @license https://www.gnu.org/licenses/gpl-3.0.html GPL v3 or later
 */

namespace Piwik\Updates;

use Piwik\Common;
use Piwik\Db;
use Piwik\Updater;
use Piwik\Updater\Migration\Factory as MigrationFactory;
use Piwik\Updates as PiwikUpdates;

/**
 * Update for version 5.7.0-b1
 */
class Updates_5_7_0_b1 extends PiwikUpdates
{
    /**
     * @var MigrationFactory
     */
    private $migration;

    public function __construct(MigrationFactory $factory)
    {
        $this->migration = $factory;
    }

    public function getMigrations(Updater $updater)
    {
        $migrations = [];

        $numericTables = Db::get()->fetchCol("SHOW TABLES LIKE '" . Common::prefixTable('archive_numeric%') . "'");
        $blobTables = Db::get()->fetchCol("SHOW TABLES LIKE '" . Common::prefixTable('archive_blob%') . "'");

        foreach (array_merge($numericTables, $blobTables) as $table) {
            $migrations[] = $this->migration->db->addColumn(Common::unprefixTable($table), 'ts_started', 'DATETIME NULL');
        }

        return $migrations;
    }

    public function doUpdate(Updater $updater)
    {
        $updater->executeMigrations(__FILE__, $this->getMigrations($updater));
    }
}
