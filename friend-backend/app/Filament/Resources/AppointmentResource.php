<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AppointmentResource\Pages;
use App\Models\Appointment;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/**
 * Bookings — mirrors the user app appointments + pro sessions agenda.
 */
class AppointmentResource extends Resource
{
    protected static ?string $model = Appointment::class;

    protected static ?string $navigationIcon = 'heroicon-o-calendar-days';

    protected static ?string $navigationGroup = 'Care';

    protected static ?string $navigationLabel = 'Bookings';

    protected static ?string $modelLabel = 'Booking';

    protected static ?string $pluralModelLabel = 'Bookings';

    protected static ?int $navigationSort = 1;

    public static function canCreate(): bool
    {
        return false;
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Session')
                ->schema([
                    Forms\Components\TextInput::make('id')->label('Booking #')->disabled(),
                    Forms\Components\TextInput::make('client.name')->label('Client')->disabled(),
                    Forms\Components\TextInput::make('professional.name')->label('Counselor')->disabled(),
                    Forms\Components\TextInput::make('professionalProfile.category.name')->label('Pillar')->disabled(),
                    Forms\Components\TextInput::make('scheduled_at')->disabled(),
                    Forms\Components\TextInput::make('duration_minutes')->suffix('min')->disabled(),
                    Forms\Components\TextInput::make('session_type')->disabled(),
                    Forms\Components\TextInput::make('status')->disabled(),
                ])
                ->columns(2),
            Forms\Components\Section::make('Payment')
                ->schema([
                    Forms\Components\TextInput::make('price_cents')
                        ->label('Price')
                        ->formatStateUsing(fn ($state, Appointment $record) =>
                            number_format(((int) $state) / 100, 2).' '.($record->currency ?? 'USD')
                        )
                        ->disabled(),
                    Forms\Components\TextInput::make('user_timezone')->disabled(),
                    Forms\Components\TextInput::make('professional_timezone')->disabled(),
                ])
                ->columns(3),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('scheduled_at', 'desc')
            ->modifyQueryUsing(fn ($q) => $q->with(['client', 'professional', 'professionalProfile.category', 'callSession']))
            ->columns([
                Tables\Columns\TextColumn::make('id')->label('#')->sortable(),
                Tables\Columns\TextColumn::make('scheduled_at')
                    ->label('When')
                    ->dateTime('M j, Y · g:i A')
                    ->sortable(),
                Tables\Columns\TextColumn::make('client.name')
                    ->label('Client')
                    ->searchable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('professional.name')
                    ->label('Counselor')
                    ->searchable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('professionalProfile.category.name')
                    ->label('Pillar')
                    ->badge()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('session_type')
                    ->label('Type')
                    ->badge()
                    ->formatStateUsing(fn (?string $state) => $state === 'video' ? 'Video' : ($state ?? '—')),
                Tables\Columns\TextColumn::make('duration_minutes')
                    ->label('Mins')
                    ->alignRight(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'confirmed', 'in_progress' => 'success',
                        'pending' => 'warning',
                        'completed' => 'info',
                        'cancelled', 'no_show' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('price_cents')
                    ->label('Price')
                    ->alignRight()
                    ->formatStateUsing(fn ($state, Appointment $record) =>
                        ((int) $state) <= 0
                            ? 'Free'
                            : number_format(((int) $state) / 100, 2).' '.($record->currency ?? 'USD')
                    ),
                Tables\Columns\IconColumn::make('call_session_present')
                    ->label('Video')
                    ->getStateUsing(fn (Appointment $record) => $record->callSession !== null)
                    ->boolean()
                    ->trueIcon('heroicon-o-video-camera')
                    ->falseIcon('heroicon-o-minus'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'confirmed' => 'Confirmed',
                        'in_progress' => 'In progress',
                        'completed' => 'Completed',
                        'cancelled' => 'Cancelled',
                    ]),
                Tables\Filters\SelectFilter::make('session_type')
                    ->options([
                        'video' => 'Video',
                        'chat' => 'Chat',
                        'in_person' => 'In person',
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAppointments::route('/'),
            'view' => Pages\ViewAppointment::route('/{record}'),
        ];
    }
}
