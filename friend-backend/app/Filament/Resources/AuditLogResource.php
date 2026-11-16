<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AuditLogResource\Pages;
use App\Models\AuditLog;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/**
 * Read-only audit log viewer. No edit / create / delete actions exposed
 * — this view is the authoritative record of every admin write.
 *
 * The AuditLogObserver (registered in AdminModuleServiceProvider) is
 * the only writer; nothing else should create rows directly.
 */
class AuditLogResource extends Resource
{
    protected static ?string $model = AuditLog::class;
    protected static ?string $navigationIcon = 'heroicon-o-document-magnifying-glass';
    protected static ?string $navigationGroup = 'Compliance';
    protected static ?string $navigationLabel = 'Audit log';
    protected static ?int $navigationSort = 50;

    public static function canCreate(): bool { return false; }
    public static function canEdit($record): bool { return false; }
    public static function canDelete($record): bool { return false; }

    public static function form(Form $form): Form
    {
        return $form->schema([
            \Filament\Forms\Components\TextInput::make('admin.name')->label('Admin')->disabled(),
            \Filament\Forms\Components\TextInput::make('action')->disabled(),
            \Filament\Forms\Components\TextInput::make('subject_type')->label('Subject type')->disabled(),
            \Filament\Forms\Components\TextInput::make('subject_id')->label('Subject ID')->disabled(),
            \Filament\Forms\Components\KeyValue::make('before')->label('Before')->disabled(),
            \Filament\Forms\Components\KeyValue::make('after')->label('After')->disabled(),
            \Filament\Forms\Components\TextInput::make('ip_address')->disabled(),
            \Filament\Forms\Components\TextInput::make('route')->disabled(),
            \Filament\Forms\Components\DateTimePicker::make('created_at')->disabled(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('admin.name')->label('Admin')->searchable(),
                Tables\Columns\TextColumn::make('action')->searchable()->limit(40),
                Tables\Columns\TextColumn::make('subject_type')->label('Subject')->formatStateUsing(fn ($state, $record) => class_basename((string) $state) . '#' . $record->subject_id),
                Tables\Columns\TextColumn::make('ip_address')->label('IP'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('action')
                    ->options(fn () => AuditLog::query()->distinct()->pluck('action', 'action')->toArray()),
                Tables\Filters\Filter::make('admin_id')
                    ->form([
                        \Filament\Forms\Components\TextInput::make('admin_id')->numeric(),
                    ])
                    ->query(function ($query, array $data): void {
                        if (! empty($data['admin_id'])) {
                            $query->where('admin_id', $data['admin_id']);
                        }
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAuditLogs::route('/'),
        ];
    }
}