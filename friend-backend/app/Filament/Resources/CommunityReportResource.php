<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CommunityReportResource\Pages;
use App\Models\CommunityReport;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Auth;

class CommunityReportResource extends Resource
{
    protected static ?string $model = CommunityReport::class;
    protected static ?string $navigationIcon = 'heroicon-o-flag';
    protected static ?string $navigationGroup = 'Community';
    protected static ?string $navigationLabel = 'Reports';
    protected static ?int $navigationSort = 51;

    public static function form(Form $form): Form
    {
        return $form->schema([
            \Filament\Forms\Components\TextInput::make('post.id')->label('Post #')->disabled(),
            \Filament\Forms\Components\TextInput::make('reporter.name')->label('Reporter')->disabled(),
            \Filament\Forms\Components\TextInput::make('reason')->disabled(),
            \Filament\Forms\Components\Textarea::make('details')->rows(3)->disabled(),
            \Filament\Forms\Components\TextInput::make('status')->disabled(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('post.id')->label('Post'),
                Tables\Columns\TextColumn::make('reporter.name')->label('Reporter'),
                Tables\Columns\TextColumn::make('reason'),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'open'      => 'warning',
                        'upheld'    => 'success',
                        'dismissed' => 'gray',
                        default     => 'gray',
                    }),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')->options(['open' => 'Open', 'upheld' => 'Upheld', 'dismissed' => 'Dismissed']),
            ])
            ->actions([
                Tables\Actions\Action::make('uphold')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->visible(fn (CommunityReport $r) => $r->status === 'open')
                    ->action(function (CommunityReport $record) {
                        $record->update(['status' => 'upheld', 'resolved_by' => Auth::id(), 'resolved_at' => now()]);
                        if ($record->post) {
                            $record->post->update(['status' => 'removed', 'moderation_reason' => 'Report upheld: ' . $record->reason, 'moderated_by' => Auth::id(), 'moderated_at' => now()]);
                        }
                    }),
                Tables\Actions\Action::make('dismiss')
                    ->icon('heroicon-o-x-circle')
                    ->color('gray')
                    ->visible(fn (CommunityReport $r) => $r->status === 'open')
                    ->action(fn (CommunityReport $record) => $record->update(['status' => 'dismissed', 'resolved_by' => Auth::id(), 'resolved_at' => now()])),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCommunityReports::route('/'),
        ];
    }
}