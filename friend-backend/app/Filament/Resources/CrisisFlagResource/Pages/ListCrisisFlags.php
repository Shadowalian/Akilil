<?php

namespace App\Filament\Resources\CrisisFlagResource\Pages;

use App\Filament\Resources\CrisisFlagResource;
use Filament\Resources\Pages\ListRecords;

class ListCrisisFlags extends ListRecords
{
    protected static string $resource = CrisisFlagResource::class;
    protected ?string $subheading = 'Open and in-review flags. Admins are the deciding step — review the source content, then mark handled or false positive.';
}