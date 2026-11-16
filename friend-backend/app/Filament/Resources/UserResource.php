<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Hash;

class UserResource extends Resource
{
    protected static ?string $model = User::class;
    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?string $navigationGroup = 'People';
    protected static ?int $navigationSort = 10;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Identity')
                ->schema([
                    Forms\Components\TextInput::make('name')->required()->maxLength(191),
                    Forms\Components\TextInput::make('email')->email()->required()->maxLength(191),
                    Forms\Components\TextInput::make('phone')->tel()->maxLength(32),
                ])
                ->columns(2),

            Forms\Components\Section::make('Role & status')
                ->schema([
                    Forms\Components\Select::make('role')
                        ->options(['user' => 'User', 'professional' => 'Professional'])
                        ->required(),
                    Forms\Components\Toggle::make('is_suspended')
                        ->dehydrated(false)   // stored in custom column below
                        ->visible(fn () => false),
                    Forms\Components\Placeholder::make('account_status')
                        ->content(fn (?User $record) => $record?->deleted_at ? 'Soft-deleted' : 'Active'),
                ])
                ->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('name')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('email')->searchable(),
                Tables\Columns\TextColumn::make('role')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'professional' => 'warning',
                        'admin'        => 'success',
                        default        => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('last_seen_at')->dateTime()->placeholder('—'),
                Tables\Columns\IconColumn::make('totp_enabled')->boolean()->label('2FA'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->options(['user' => 'User', 'professional' => 'Professional']),
                Tables\Filters\TernaryFilter::make('totp_enabled')->label('Has 2FA'),
            ])
            ->actions([
                Tables\Actions\Action::make('suspend')
                    ->icon('heroicon-o-no-symbol')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn (User $record) => $record->deleted_at === null)
                    ->action(function (User $record) {
                        $record->delete();   // soft-delete = suspend
                    }),
                Tables\Actions\Action::make('reactivate')
                    ->icon('heroicon-o-arrow-uturn-left')
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn (User $record) => $record->deleted_at !== null)
                    ->action(function (User $record) {
                        $record->restore();
                    }),
                Tables\Actions\ViewAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkAction::make('suspend_bulk')
                    ->label('Suspend selected')
                    ->requiresConfirmation()
                    ->action(fn ($records) => $records->each->delete()),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListUsers::route('/'),
            'view'   => Pages\ViewUser::route('/{record}'),
            'edit'   => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}