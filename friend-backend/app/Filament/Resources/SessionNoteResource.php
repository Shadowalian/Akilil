<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SessionNoteResource\Pages;
use App\Models\SessionNote;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/**
 * Clinical Session Notes (SOAP notes & homework) written by professionals.
 * Governed under HIPAA/clinical compliance standards.
 */
class SessionNoteResource extends Resource
{
    protected static ?string $model = SessionNote::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';

    protected static ?string $navigationGroup = 'Care';

    protected static ?string $navigationLabel = 'Clinical Notes';

    protected static ?string $modelLabel = 'Clinical Note';

    protected static ?string $pluralModelLabel = 'Clinical Notes';

    protected static ?int $navigationSort = 3;

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
            Forms\Components\Section::make('Session Metadata')
                ->schema([
                    Forms\Components\TextInput::make('appointment_id')->label('Booking #')->disabled(),
                    Forms\Components\TextInput::make('professional.name')->label('Counselor (Author)')->disabled(),
                    Forms\Components\TextInput::make('client.name')->label('Client')->disabled(),
                    Forms\Components\TextInput::make('created_at')->label('Timestamp')->disabled(),
                ])
                ->columns(2),
            Forms\Components\Section::make('Clinical SOAP Documentation')
                ->schema([
                    Forms\Components\Textarea::make('notes')
                        ->label('Session Notes')
                        ->rows(8)
                        ->disabled(),
                    Forms\Components\KeyValue::make('tags')
                        ->label('Diagnostic & Clinical Tags')
                        ->disabled(),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->modifyQueryUsing(fn ($q) => $q->with(['appointment', 'professional', 'client']))
            ->columns([
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('M j, Y · g:i A')
                    ->sortable(),
                Tables\Columns\TextColumn::make('professional.name')
                    ->label('Counselor')
                    ->searchable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('client.name')
                    ->label('Client')
                    ->searchable()
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('appointment_id')
                    ->label('Booking #')
                    ->sortable(),
                Tables\Columns\TextColumn::make('notes')
                    ->label('SOAP Summary')
                    ->limit(60)
                    ->tooltip(fn (SessionNote $r) => $r->notes)
                    ->placeholder('—'),
                Tables\Columns\TagsColumn::make('tags')
                    ->label('Clinical Tags')
                    ->placeholder('No tags'),
            ])
            ->filters([
                Tables\Filters\Filter::make('created_at')
                    ->form([
                        Forms\Components\DatePicker::make('from'),
                        Forms\Components\DatePicker::make('to'),
                    ])
                    ->query(fn ($q, array $data) => $q
                        ->when($data['from'] ?? null, fn ($q, $d) => $q->whereDate('created_at', '>=', $d))
                        ->when($data['to'] ?? null, fn ($q, $d) => $q->whereDate('created_at', '<=', $d))
                    ),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSessionNotes::route('/'),
        ];
    }
}
