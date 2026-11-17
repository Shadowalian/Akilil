<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SafetyPlanResource\Pages;
use App\Models\SafetyPlan;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/** Read-only: safety staff can read a person's plan when following up. */
class SafetyPlanResource extends Resource
{
    protected static ?string $model = SafetyPlan::class;

    protected static ?string $navigationIcon = 'heroicon-o-lifebuoy';

    protected static ?string $navigationGroup = 'Safety';

    protected static ?string $navigationLabel = 'Safety plans';

    public static function canAccess(): bool
    {
        return auth()->user()?->hasAnyRole(['admin', 'support']) ?? false;
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('updated_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('user.name')->label('Person')->searchable(),
                Tables\Columns\TextColumn::make('user.phone')->label('Phone')->placeholder('—'),
                Tables\Columns\TextColumn::make('updated_at')->label('Last updated')->since(),
            ])
            ->actions([Tables\Actions\ViewAction::make()]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        $list = fn (string $key) => fn (SafetyPlan $r) => $r->plan[$key] ?? [];

        return $infolist->schema([
            Infolists\Components\TextEntry::make('user.name')->label('Person'),
            Infolists\Components\TextEntry::make('user.phone')->label('Phone')->placeholder('—'),
            Infolists\Components\TextEntry::make('warning_signs')->label('Warning signs')->state($list('warning_signs'))->listWithLineBreaks()->placeholder('—')->columnSpanFull(),
            Infolists\Components\TextEntry::make('coping')->label('Things that help')->state($list('coping'))->listWithLineBreaks()->placeholder('—')->columnSpanFull(),
            Infolists\Components\TextEntry::make('people')->label('People they can call')
                ->state(fn (SafetyPlan $r) => collect($r->plan['people'] ?? [])->map(fn ($p) => $p['name'].(! empty($p['phone']) ? ' — '.$p['phone'] : ''))->all())
                ->listWithLineBreaks()->placeholder('—')->columnSpanFull(),
            Infolists\Components\TextEntry::make('environment')->label('Making things safer')->state($list('environment'))->listWithLineBreaks()->placeholder('—')->columnSpanFull(),
        ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSafetyPlans::route('/'),
            'view'  => Pages\ViewSafetyPlan::route('/{record}'),
        ];
    }
}
