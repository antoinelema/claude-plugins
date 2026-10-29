<?php

declare(strict_types=1);

namespace Tests\__Domain__;

use PHPat\Selector\Selector;
use PHPat\Test\Builder\Rule;
use PHPat\Test\PHPat;

/**
 * Règles d'architecture vérifiées par PHPStan via phpat (`phpstan analyse`),
 * et non par PHPUnit.
 *
 * À déclarer dans phpstan.neon :
 *   includes:
 *     - ./vendor/phpat/phpat/extension.neon
 *   services:
 *     - class: Tests\__Domain__\DomainDependencyRules
 *       tags: [phpat.test]
 *
 * Adapter les namespaces à paths.domain / paths.application de .claude/nabc.json.
 */
final class DomainDependencyRules
{
    public function test_domain_does_not_depend_on_outer_layers(): Rule
    {
        return PHPat::rule()
            ->classes(Selector::inNamespace('App\__Domain__'))
            ->shouldNotDependOn()
            ->classes(
                Selector::inNamespace('App\__Infrastructure__'),
                Selector::inNamespace('App\__Application__'),
                Selector::inNamespace('App\Http'),
                Selector::inNamespace('App\Jobs'),
                Selector::inNamespace('App\Console'),
                Selector::inNamespace('App\Providers'),
                Selector::inNamespace('Illuminate'),
            )
            ->because('le Domain définit ses propres interfaces, implémentées dans l\'Infrastructure.');
    }
}
