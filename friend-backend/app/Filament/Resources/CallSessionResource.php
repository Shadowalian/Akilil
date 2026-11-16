<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CallSessionResource\Pages;
use App\Models\CallSession;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/**
 * Live video rooms (Jitsi) — same rooms the Flutter apps join via session/start.
 */
class CallSessionResource extends Resource
{
    protected static ?string $model = CallSession::class;

    protected static ?string $navigationIcon = 'heroicon-o-video-camera';

    protected static ?string $navigationGroup = 'Care';

    protected static ?string $navigationLabel = 'Video sessions';

    protected static ?string $modelLabel = 'Video session';

    protected static ?string $pluralModelLabel = 'Video sessions';

    protected static ?int $navigationSort = 2;

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('appointment_id')->label('Booking #')->disabled(),
            Forms\Components\TextInput::make('appointment.professional.name')->label('Counselor (host)')->disabled(),
            Forms\Components\TextInput::make('appointment.client.name')->label('Client')->disabled(),
            Forms\Components\TextInput::make('provider')->disabled(),
            Forms\Components\TextInput::make('room_name')->disabled(),
            Forms\Components\TextInput::make('status')->disabled(),
            Forms\Components\TextInput::make('started_at')->disabled(),
            Forms\Components\TextInput::make('ended_at')->disabled(),
            Forms\Components\TextInput::make('duration_seconds')->disabled(),
            Forms\Components\TextInput::make('recording_status')->disabled(),
            Forms\Components\TextInput::make('recording_url')->url()->disabled(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('started_at', 'desc')
            ->modifyQueryUsing(fn ($q) => $q->with(['appointment.client', 'appointment.professional']))
            ->columns([
                Tables\Columns\TextColumn::make('started_at')
                    ->label('Started')
                    ->dateTime('M j · g:i A')
                    ->sortable(),
                Tables\Columns\TextColumn::make('appointment.professional.name')
                    ->label('Counselor')
                    ->searchable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('appointment.client.name')
                    ->label('Client')
                    ->searchable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('appointment_id')
                    ->label('Booking')
                    ->sortable(),
                Tables\Columns\TextColumn::make('room_name')
                    ->label('Jitsi room')
                    ->limit(24)
                    ->tooltip(fn (CallSession $r) => $r->room_name)
                    ->copyable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('provider')
                    ->badge()
                    ->formatStateUsing(fn (?string $s) => $s ?: 'jitsi'),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (?string $state) => match ($state) {
                        'active' => 'success',
                        'completed' => 'info',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('duration_seconds')
                    ->label('Duration')
                    ->formatStateUsing(fn ($s) => $s ? gmdate('H:i:s', (int) $s) : '—')
                    ->alignRight(),
                Tables\Columns\IconColumn::make('recording_url')
                    ->label('Rec')
                    ->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'active' => 'Active',
                        'completed' => 'Completed',
                        'pending' => 'Pending',
                    ]),
                Tables\Filters\Filter::make('started_at')
                    ->form([
                        Forms\Components\DatePicker::make('from'),
                        Forms\Components\DatePicker::make('to'),
                    ])
                    ->query(fn ($q, array $data) => $q
                        ->when($data['from'] ?? null, fn ($q, $d) => $q->whereDate('started_at', '>=', $d))
                        ->when($data['to'] ?? null, fn ($q, $d) => $q->whereDate('started_at', '<=', $d))
                    ),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCallSessions::route('/'),
        ];
    }
}
