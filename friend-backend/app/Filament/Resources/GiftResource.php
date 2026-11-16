<?php

namespace App\Filament\Resources;

use App\Filament\Resources\GiftResource\Pages;
use App\Models\Gift;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/** The live-gift catalogue: what viewers can send and what each costs. */
class GiftResource extends Resource
{
    protected static ?string $model = Gift::class;

    protected static ?string $navigationIcon = 'heroicon-o-gift';

    protected static ?string $navigationGroup = 'Live';

    protected static ?int $navigationSort = 2;

    public static function canAccess(): bool
    {
        return auth()->user()?->hasRole('admin') ?? false;
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('name')->required()->maxLength(64),
            Forms\Components\TextInput::make('slug')->required()->maxLength(48)->unique(ignoreRecord: true),
            Forms\Components\TextInput::make('emoji')->required()->maxLength(16),
            Forms\Components\TextInput::make('price_cents')->label('Price (minor units)')
                ->numeric()->required()->minValue(1)
                ->helperText('In '.config('akilil.currency').' minor units. 500 = 5.00'),
            Forms\Components\Select::make('animation')->required()->options([
                'float' => 'Float (small)',
                'burst' => 'Burst (medium)',
                'fullscreen' => 'Full screen (premium)',
            ]),
            Forms\Components\TextInput::make('sort_order')->numeric()->default(0),
            Forms\Components\Toggle::make('is_active')->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('sort_order')
            ->columns([
                Tables\Columns\TextColumn::make('emoji')->label(''),
                Tables\Columns\TextColumn::make('name')->searchable(),
                Tables\Columns\TextColumn::make('price_cents')->label('Price')
                    ->formatStateUsing(fn ($state) => number_format($state / 100, 2).' '.config('akilil.currency'))
                    ->sortable(),
                Tables\Columns\TextColumn::make('animation')->badge(),
                Tables\Columns\IconColumn::make('is_active')->boolean()->label('Active'),
            ])
            ->actions([Tables\Actions\EditAction::make()]);
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListGifts::route('/'),
            'create' => Pages\CreateGift::route('/create'),
            'edit'   => Pages\EditGift::route('/{record}/edit'),
        ];
    }
}
