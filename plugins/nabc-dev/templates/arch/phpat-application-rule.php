<?php

declare(strict_types=1);

namespace Tests\__Application__;

use PHPat\Selector\Selector;
use PHPat\Test\Builder\Rule;
use PHPat\Test\PHPat;

/**
 * Règles d'architecture vérifiées par PHPStan via phpat (`phpstan analyse`),
 * et non par PHPUnit. Décision : docs/adr/<date>-decoupage-des-couches.md.
 *
 * À déclarer dans phpstan.neon, à côté de la règle du domaine :
 *   services:
 *     - class: Tests\__Application__\ApplicationDependencyRules
 *       tags: [phpat.test]
 *
 * Ne viser que l'orchestration (cas d'usage, services, listeners). Les
 * adaptateurs d'entrée (contrôleurs, commandes, jobs, tools MCP) assemblent
 * l'infrastructure et restent hors de la règle : les lister dans l'ADR.
 * Violations existantes : `phpstan analyse --generate-baseline phpstan-baseline.neon`.
 */
final class ApplicationDependencyRules
{
    public function test_application_does_not_depend_on_infrastructure(): Rule
    {
        return PHPat::rule()
            ->classes(
                Selector::inNamespace('App\__Application__\UseCase'),
                Selector::inNamespace('App\__Application__\Services'),
                Selector::inNamespace('App\__Application__\Listeners'),
            )
            ->shouldNotDependOn()
            ->classes(
                Selector::inNamespace('App\__Infrastructure__'),
                Selector::classname('Illuminate\Support\Facades\DB'),
            )
            ->because('l\'application passe par les ports du domaine, implémentés dans l\'Infrastructure.');
    }
}
