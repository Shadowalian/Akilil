<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CrisisFlagResource\Pages;
use App\Models\CrisisFlag;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Auth;

/**
 * High-visibility crisis-flag queue.
 *
 * IMPORTANT — this view is a reviewer tool, not a diagnostic surface.
 * Admin/support staff are the deciding step. Do NOT add auto-actions
 * (auto-message-user, auto-call-emergency-services, etc.) to this view.
 * Any irreversible outreach happens only after a human has read the
 * context and made a call.
 */
class CrisisFlagResource extends Resource
{
    protected static ?string $model = CrisisFlag::class;
    protected static ?string $navigationIcon = 'heroicon-o-exclamation-triangle';
    protected static ?string $navigationGroup = 'Safety';
    protected static ?string $navigationLabel = 'Crisis flags';
    protected static ?int $navigationSort = 40;
    protected static ?string $modelLabel = 'Crisis flag';

    public static function getNavigationBadge(): ?string
    {
        return (string) static::getModel()::where('status', 'open')->count() ?: null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'danger';
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Flag')
                ->schema([
                    Forms\Components\TextInput::make('user.name')->label('User')->disabled(),
                    Forms\Components\TextInput::make('user.email')->label('Email')->disabled(),
                    Forms\Components\TextInput::make('severity')->numeric()->step('0.001')->disabled(),
                    Forms\Components\TextInput::make('source_type')->label('Source')->disabled(),
                    Forms\Components\TextInput::make('status')->disabled(),
                    Forms\Components\KeyValue::make('matched_signals')->disabled(),
                ])
                ->columns(2),
            Forms\Components\Section::make('Reviewer notes')
                ->schema([
                    Forms\Components\Textarea::make('handling_notes')->rows(4),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable()->label('Flagged'),
                Tables\Columns\TextColumn::make('user.name')->label('User')->searchable(),
                Tables\Columns\TextColumn::make('severity')
                    ->formatStateUsing(fn ($state) => number_format((float) $state, 3))
                    ->badge()
                    ->color(fn ($state) => ((float) $state) >= 0.85 ? 'danger' : 'warning'),
                Tables\Columns\TextColumn::make('source_type')->label('Source'),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'open'           => 'danger',
                        'in_review'      => 'warning',
                        'handled'        => 'success',
                        'false_positive' => 'gray',
                        default          => 'gray',
                    }),
                Tables\Columns\TextColumn::make('handledBy.name')->label('Handler')->placeholder('—'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options(['open' => 'Open', 'in_review' => 'In review', 'handled' => 'Handled', 'false_positive' => 'False positive']),
                Tables\Filters\TernaryFilter::make('severity')->queries(
                    true:  fn ($q) => $q->where('severity', '>=', 0.85),
                    false: fn ($q) => $q->where('severity', '<', 0.85),
                )->label('High severity (≥ 0.85)'),
            ])
            ->actions([
                Tables\Actions\Action::make('mark_handled')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->visible(fn (CrisisFlag $r) => in_array($r->status, ['open', 'in_review']))
                    ->form([
                        Forms\Components\Textarea::make('handling_notes')->required(),
                    ])
                    ->action(function (CrisisFlag $record, array $data) {
                        $record->update([
                            'status'        => 'handled',
                            'handled_by'   => Auth::id(),
                            'handled_at'   => now(),
                            'handling_notes'=> $data['handling_notes'],
                        ]);
                        Notification::make()->title('Flag marked handled')->success()->send();
                    }),
                Tables\Actions\Action::make('mark_false_positive')
                    ->icon('heroicon-o-x-mark')
                    ->color('gray')
                    ->visible(fn (CrisisFlag $r) => in_array($r->status, ['open', 'in_review']))
                    ->form([Forms\Components\Textarea::make('handling_notes')->required()])
                    ->action(function (CrisisFlag $record, array $data) {
                        $record->update([
                            'status'        => 'false_positive',
                            'handled_by'   => Auth::id(),
                            'handled_at'   => now(),
                            'handling_notes'=> $data['handling_notes'],
                        ]);
                        Notification::make()->title('Flag marked false positive')->info()->send();
                    }),
                Tables\Actions\Action::make('assign_to_me')
                    ->icon('heroicon-o-user-plus')
                    ->visible(fn (CrisisFlag $r) => $r->handled_by === null)
                    ->action(fn (CrisisFlag $record) => $record->update([
                        'handled_by' => Auth::id(),
                        'status'     => 'in_review',
                    ])),
                Tables\Actions\ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCrisisFlags::route('/'),
            'view'  => Pages\ViewCrisisFlag::route('/{record}'),
        ];
    }
}