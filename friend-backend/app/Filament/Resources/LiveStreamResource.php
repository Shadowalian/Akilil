<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LiveStreamResource\Pages;
use App\Models\LiveStream;
use App\Services\LiveFeedService;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

/**
 * Live broadcasts — what is on air, how it performed, and a kill switch
 * for moderators.
 */
class LiveStreamResource extends Resource
{
    protected static ?string $model = LiveStream::class;

    protected static ?string $navigationIcon = 'heroicon-o-signal';

    protected static ?string $navigationGroup = 'Live';

    protected static ?string $navigationLabel = 'Broadcasts';

    protected static ?int $navigationSort = 1;

    public static function canCreate(): bool
    {
        return false;
    }

    public static function getNavigationBadge(): ?string
    {
        $live = LiveStream::where('status', 'live')->count();

        return $live ? (string) $live : null;
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('scheduled_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('title')->searchable()->limit(40),
                Tables\Columns\TextColumn::make('professional.name')->label('Host')->searchable(),
                Tables\Columns\TextColumn::make('category.name')->label('Pillar')->badge(),
                Tables\Columns\TextColumn::make('status')->badge()->color(fn (string $state) => match ($state) {
                    'live' => 'danger', 'scheduled' => 'warning', 'ended' => 'gray', default => 'gray',
                }),
                Tables\Columns\TextColumn::make('scheduled_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('peak_viewers')->label('Peak')->sortable(),
                Tables\Columns\TextColumn::make('total_viewers')->label('Viewers')->sortable(),
                Tables\Columns\TextColumn::make('gifts_total_cents')->label('Gifts')
                    ->formatStateUsing(fn ($state) => number_format($state / 100, 2))
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')->options([
                    'live' => 'Live', 'scheduled' => 'Scheduled', 'ended' => 'Ended', 'cancelled' => 'Cancelled',
                ]),
            ])
            ->actions([
                Tables\Actions\Action::make('end')
                    ->label('End broadcast')
                    ->icon('heroicon-o-stop-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn (LiveStream $record) => $record->status === 'live'
                        && (auth()->user()?->hasAnyRole(['admin', 'moderator']) ?? false))
                    ->action(function (LiveStream $record) {
                        $record->update(['status' => 'ended', 'ended_at' => now()]);
                        app(LiveFeedService::class)->system($record, 'ended', ['by' => 'moderator']);
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return ['index' => Pages\ListLiveStreams::route('/')];
    }
}
